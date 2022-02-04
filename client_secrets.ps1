## References
### Graph API: https://docs.microsoft.com/en-us/graph/api/resources/application?view=graph-rest-1.0

Param(
  [string]$targetTenantId,
  [string]$targetClientId,
  [string]$environment,
  [string]$product,
  [string]$prefix,
  [string]$keyVaultName 
 )
 
#############################################################
###           Get Automation Context                      ###
#############################################################

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null
 
# Connect using a Managed Service Identity
try {
  $AutomationContext = (Connect-AzAccount -Identity).context
}
catch {
  Write-Output "There is no system-assigned user identity. Aborting."; 
  exit
}


#############################################################
###           Set Target Context                          ###
#############################################################

if ($null -eq $targetTenantId -or $targetTenantId -eq "") {

  $targetContext = $AutomationContext
}
else {
  # Connect to target Tenant
  try {
    $targetContext = (Connect-AzAccount -Identity -TenantId $targetTenantId -AccountId $targetClientId ).context
  }
  catch {
    Write-Output "Failed to connect remote tenant. Aborting."; 
    Write-Error "Error: $($_)"; 
    exit
  }
}

$targetContext = Set-AzContext -Context $targetContext

try {
  Write-Host "Check Microsoft.Graph.Applications module installed"
  Get-InstalledModule -Name Microsoft.Graph.Applications -Erroraction stop
}
catch {
  Write-Host "Install Microsoft.Graph.Applications module"
  Install-Module -Name Microsoft.Graph.Applications -Scope CurrentUser -Force -Confirm:$false
}

$token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/"
Connect-MgGraph -AccessToken $token.Token


#############################################################
###           Remote Expired Secrets                      ###
#############################################################
 
Write-Host "----- EXPIRED SECRETS -----"
$Applications = Get-MgApplication
     
foreach ($app in $Applications) {
  $appName = $app.DisplayName
  $appId = $app.AppId
  $secret = $app.PasswordCredentials
  
  Write-Host "Checking $appName for expired Secrets"

  foreach ($s in $secret) {
    $keyName = $s.DisplayName 
    if ($keyName -like "$prefix-*") {
      $keyId = $s.KeyId
      Write-Host "$appName Secret $keyName"

      $endDate = $s.EndDateTime
      $currentDate = Get-Date
    
      Write-Host "$keyName has expires $endDate"
      if ($endDate -lt $currentDate) {
        Write-Host "$keyName has expired ($endDate). Removing Key"
        $params = @{
          KeyId = $keyId
        }
      
        Remove-MgApplicationPassword -ApplicationId $appId -BodyParameter $params
      }
    }
  }
  
}

#############################################################
###           Create New Secrets if not exist             ###
#############################################################

Write-Host "----- NO SECRETS -----"
$Applications = Get-MgApplication

foreach ($app in $Applications) {
  $appName = $app.DisplayName
  $appId = $app.AppId
  $secret = $app.PasswordCredentials
  $secretName = "$prefix-$product-$environment-$appName"
  
  Write-Host "Checking $appName has automated secrets"

  $secretExists = $secret.DisplayName -contains $secretName

  if (!$secretExists) {
    Write-Host "Creating Secret $secretName"
    $params = @{
      PasswordCredential = @{
        DisplayName = "$secretName-$($(Get-Date).ToString('yyyyMMddhhmmss'))"
        EndDateTime = $(Get-Date).AddYears($expiryFromNowYears)
      }
    }
    
    $createdPassword = Add-MgApplicationPassword -ApplicationId $appId -BodyParameter $params

    ## Add/Update Secret 
    $secretvalue = ConvertTo-SecureString $createdPassword.SecretText -AsPlainText -Force
    $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secretvalue -DefaultProfile $AutomationContext
  }
  
}

#############################################################
###           Create New Secrets if expiring              ###
#############################################################
 
Write-Host "----- RECYCLE SECRETS -----"
$expiringRangeDays = 30
$expiryFromNowYears = 1

$Applications = Get-MgApplication
     
foreach ($app in $Applications) {
  $appName = $app.DisplayName
  $appId = $app.AppId
  $secret = $app.PasswordCredentials
  
  Write-Host "Checking $appName"

  foreach ($s in $secret) {
    if ($keyName -like "$prefix-*") {
      $keyName = $s.DisplayName 
      $keyId = $s.KeyId
      Write-Host "$appName Secret $keyName"

      $endDate = $s.EndDateTime
      $expiringRangeDate = $(Get-Date).AddDays($expiringRangeDays)
    
      Write-Host "$keyName has expires $endDate"
      Write-Host "Expiry Date Range is $expiringRangeDate"
      if ($endDate -lt $expiringRangeDate) {
        Write-Host "$keyName will expire within $expiringRangeDays."
        $secretName = "$prefix-$product-$environment-$appName"

        Write-Host "Creating Secret $secretName"
        $params = @{
          PasswordCredential = @{
            DisplayName = "$secretName-$($(Get-Date).ToString('yyyyMMddhhmmss'))"
            EndDateTime = $(Get-Date).AddYears($expiryFromNowYears)
          }
        }
        
        $createdPassword = Add-MgApplicationPassword -ApplicationId $appId -BodyParameter $params

        ## Add/Update Secret 
        $secretvalue = ConvertTo-SecureString $createdPassword.SecretText -AsPlainText -Force
        $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secretvalue -DefaultProfile $AutomationContext
        
      }
    }
  }
  
}

#############################################################
###           Disconnect                                  ###
#############################################################

Disconnect-MgGraph