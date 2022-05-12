Param(
  [string]$source_client_id,
  [string]$source_tenant_id,

  [string]$target_tenant_id,
  [string]$target_application_id,
  [string]$target_application_secret,

  [array]$application_id_collection,

  [string]$environment,
  [string]$product,
  [string]$prefix,

  [string]$key_vault_name 
)

$application_id_collection_arr = $application_id_collection.Split(',')
if ($application_id_collection_arr.length -lt 1) {
  Write-Warning "No Applications to process. $application_id_collection"; 
  exit
}
else {
  Write-Output "there is Applications to process. $application_id_collection"; 
}

#############################################################
###           Get Current Context                      ###
#############################################################

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null
 
# Connect using a Managed Service Identity
try {
  $sourceContext = (Connect-AzAccount -Identity -TenantId $source_tenant_id -AccountId $source_client_id ).context
}
catch {
  Write-Error "Cannot connect to the source Managed Identity $source_client_id in $source_tenant_id. Aborting."; 
  exit
}

#############################################################
###           Set Target Context                          ###
#############################################################

if ($null -eq $target_tenant_id -or $target_tenant_id -eq "") {

  $targetContext = $sourceContext
}
else {
  # Connect to target Tenant
  try {
    $password = ConvertTo-SecureString $target_application_secret -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential ($target_application_id, $password)
    $targetContext = (Connect-AzAccount -ServicePrincipal -TenantId $target_tenant_id -Credential $Credential).context
  }
  catch {
    Write-Error "Failed to connect remote tenant. Error: $($_)"; 
    exit
  }
}

$targetContext = Set-AzContext -Context $targetContext

#############################################################
###           Common Functions                           ###
#############################################################

function GeneratePassword {
  function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs = ""
    return [String]$characters[$random]
  }
 
  function ScrambleString([string]$inputString) {     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
  }
 
  $password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
  $password += Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
  $password += Get-RandomCharacters -length 1 -characters '1234567890'
  $password += Get-RandomCharacters -length 1 -characters '!"§$%&/()=?}][{@#*+'
 
  $password = ScrambleString $password

  return $password
}

#############################################################
###           Process Applications                        ###
#############################################################
try {
  $Applications = Get-AzADApplication -DefaultProfile $targetContext
  Write-Output "Applications Found:"
  foreach ($app in $Applications.DisplayName) {
    Write-Output "$app - $($app.Id)"
  }

  $expiringRangeDays = 30
  $expiryFromNowYears = 1

  Write-Output "Start Processing"
  foreach ($application_id in $application_id_collection_arr) {
  
    Write-Output "Starting $application_id"
    $containsApp = $Applications.Id -contains $application_id

    Write-Output "Contained?  $containsApp"
    if ($containsApp) {

      try {
        $app = $Applications | Where-Object { $_.Id -eq $application_id }

        $appName = $app.DisplayName
        $objectId = $app.Id
        $appId = $app.ApplicationId.ToString()
        Write-Output "Got App $appName"

        $secrets = Get-AzADAppCredential -ObjectId $objectId -DefaultProfile $targetContext
        Write-Output "Got $($secrets.length) Secrets in Total"

        $kvSecretName = "$prefix-$product-$environment-$appName"
        $secretStartDate = Get-Date 
        $secretEndDate = $secretStartDate.AddYears($expiryFromNowYears) 
        $StringPassword = GeneratePassword
        $SecureStringPassword = ConvertTo-SecureString $StringPassword -AsPlainText -Force
        $displayNamePrefix = "$prefix-pwd"
        $displayName = "$displayNamePrefix-$($(Get-Date).ToString('yyyyMMddhhmmss'))"
  
        Write-Output "Checking $appName has automated secrets"

        $filteredSecrets = $($secrets | Where-Object { $_.CustomKeyIdentifier -like "$displayNamePrefix*" })
        $secretCount = $filteredSecrets.length
        $secretExists = ($secretCount -gt 0 -and $null -ne $secrets)
        Write-Output "Length: $secretCount"
        Write-Output "Auto Secret Exits? $secretExists"
  
        if (!$secretExists) {
          Write-Output "Creating Secret $kvSecretName"
          New-AzADAppCredential -ObjectId $objectId -Password $SecureStringPassword -StartDate $secretStartDate -EndDate $secretEndDate -CustomKeyIdentifier $displayName -DefaultProfile $targetContext

          ## Add/Update Secret 
          Write-Output "Saving Secret to $key_vault_name"
          $secretvalue = ConvertTo-SecureString $StringPassword -AsPlainText -Force
          Set-AzKeyVaultSecret -VaultName $key_vault_name -Name "$kvSecretName-pwd" -SecretValue $secretvalue -DefaultProfile $sourceContext
          Write-Output "Saving ID to $key_vault_name"
          $secretvalue = ConvertTo-SecureString $appId -AsPlainText -Force
          Set-AzKeyVaultSecret -VaultName $key_vault_name -Name "$kvSecretName-id" -SecretValue $secretvalue -DefaultProfile $sourceContext
        }
        else {

          Write-Output "Recycling $appName Secrets STARTED"
          
          $validSecrets = $false
          foreach ($s in $filteredSecrets) {
            $keyName = $s.CustomKeyIdentifier 
            Write-Output "Secret: $keyName"
            $keyId = $s.KeyId
            Write-Output "$appName Secret $keyName"
  
            $endDate = Get-Date($s.EndDate) 
            $currentDate = Get-Date
            $expiringRangeDate = $(Get-Date).AddDays($expiringRangeDays)

            $endDateObj = ($endDate - $currentDate)
            $expiringRangeDateObj = ($endDate - $currentDate)

            Write-Output "$keyName has expires $endDate. It has $($endDateObj.Days) days"
            Write-Output "Expiry Date Range is $expiringRangeDate. It has $($expiringRangeDateObj.Days) day"
            if ($endDateObj.Days -lt 1) {
              Write-Output "$keyName has expired ($endDate). Removing Key"
              Remove-AzADAppCredential -ObjectId $appId -KeyId $keyId -Confirm:$false -DefaultProfile $targetContext
            }
            elseif ($expiringRangeDateObj.Days -lt $expiringRangeDays) {
              Write-Output "$keyName will expire within $expiringRangeDays."           
            }
            else {
              Write-Output "$kvSecretName secret is not expiring"
              $validSecrets = $true
            }
           
          }

          if (!$validSecrets) {
            Write-Output "There are no valid secrets"
    
            Write-Output "Creating Secret $kvSecretName"
            New-AzADAppCredential -ObjectId $objectId -Password $SecureStringPassword -StartDate $secretStartDate -EndDate $secretEndDate -CustomKeyIdentifier $displayName -DefaultProfile $targetContext
    
            ## Add/Update Secret 
            $secretvalue = ConvertTo-SecureString $StringPassword -AsPlainText -Force
            Set-AzKeyVaultSecret -VaultName $key_vault_name -Name "$kvSecretName-pwd" -SecretValue $secretvalue -DefaultProfile $sourceContext
          }

          Write-Output "Recycling $appName Secrets ENDED"
        }
      }
      catch {
        Write-Error "Failed to update secret: $application_id. Aborting."; 
        Write-Error "Error: $($_)"; 
        exit
      }
    
      Write-Output "Ending $application_id"
    }
    else {
      Write-Warning "$application_id is not found in the Application Collection."
    }
    Write-Output "Nexted"
  }
  Write-Output "End Processing"

}
catch {
  Write-Error "Failed to process secrets. Aborting."; 
  Write-Error "Error: $($_)"; 
  exit
}

Write-Output "Completed"