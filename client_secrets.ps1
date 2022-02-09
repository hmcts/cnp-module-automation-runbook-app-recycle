## References
### Graph API: https://docs.microsoft.com/en-us/graph/api/resources/application?view=graph-rest-1.0

Param(
  [string]$sourceClientId,
  [string]$sourceTenantId,

  [string]$targetTenantId,
  [string]$targetApplicationId,
  [string]$targetApplicationSecret,

  [array]$servicePrincipalIdCollection,

  [string]$environment,
  [string]$product,
  [string]$prefix,

  [string]$keyVaultName 
)
 
#############################################################
###           Get Current Context                      ###
#############################################################

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null
 
# Connect using a Managed Service Identity
try {
  $sourceContext = (Connect-AzAccount -Identity -TenantId $sourceTenantId -AccountId $sourceClientId ).context
}
catch {
  Write-Output "Cannot connect to the source Managed Identity $sourceClientId in $sourceTenantId. Aborting."; 
  exit
}


#############################################################
###           Set Target Context                          ###
#############################################################

if ($null -eq $targetTenantId -or $targetTenantId -eq "") {

  $targetContext = $sourceContext
}
else {
  # Connect to target Tenant
  try {
    $password = ConvertTo-SecureString $targetApplicationSecret -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential ($targetApplicationId, $password)
    $targetContext = (Connect-AzAccount -ServicePrincipal -TenantId $targetTenantId -Credential $Credential).context
  }
  catch {
    Write-Output "Failed to connect remote tenant. Aborting."; 
    Write-Error "Error: $($_)"; 
    exit
  }
}

$targetContext = Set-AzContext -Context $targetContext


#############################################################
###           Setup script                                ###
#############################################################
try {
  Write-Host "Check Microsoft.Graph.Applications module installed"
  Get-InstalledModule -Name Microsoft.Graph.Applications -Erroraction stop
}
catch {
  Write-Host "Install Microsoft.Graph.Applications module"
  Install-Module -Name Microsoft.Graph.Applications -Scope CurrentUser -Force -Confirm:$false
}

Write-Host "Connect to Graph API"
$token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/"
Connect-MgGraph -AccessToken $token.Token


#############################################################
###           Process Service Principals                  ###
#############################################################

$Applications = Get-MgApplication

$expiringRangeDays = 30
$expiryFromNowYears = 1

foreach ($spId in $servicePrincipalIdCollection) {
  
  $containsApp = $Applications.Id -contains $spId

  if ($containsApp) {

    $app = $Applications | Where-Object { $_.Id -eq $spId }

    $appName = $app.DisplayName
    $appId = $app.Id
    $secret = $app.PasswordCredentials

    $secretName = "$prefix-$product-$environment-$appName"
  
    Write-Host "Checking $appName has automated secrets"
  
    $secretExists = $($secret.DisplayName -like "$secretName*").length -gt 0
  
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
      $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "$secretName-pwd" -SecretValue $secretvalue -DefaultProfile $sourceContext
    }
    else {

      Write-Host "Recycling $appName Secrets"
      
      foreach ($s in $secret) {
        $keyName = $s.DisplayName 
        if ($keyName -like "$secretName*") {
          $keyId = $s.KeyId
          Write-Host "$appName Secret $keyName"
  
          $endDate = $s.EndDateTime
          $currentDate = Get-Date
          $expiringRangeDate = $(Get-Date).AddDays($expiringRangeDays)
      
          Write-Host "$keyName has expires $endDate"
          Write-Host "Expiry Date Range is $expiringRangeDate"
          if ($endDate -lt $currentDate) {
            Write-Host "$keyName has expired ($endDate). Removing Key"
            $params = @{
              KeyId = $keyId
            }
        
            Remove-MgApplicationPassword -ApplicationId $appId -BodyParameter $params
          }
          elseif ($endDate -lt $expiringRangeDate) {
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
            $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "$secretName-pwd" -SecretValue $secretvalue -DefaultProfile $sourceContext
            
          }
          else {
            Write-Host "$secretName secret is not exiring"
          }
        }
      }
    }
    
    $secretvalue = ConvertTo-SecureString $appId -AsPlainText -Force
    $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "$secretName-id" -SecretValue $secretvalue -DefaultProfile $sourceContext
  }
  else {
    Write-Output "$spId is not found in the Application Collection."
  }
}

#############################################################
###           Disconnect                                  ###
#############################################################

Disconnect-MgGraph