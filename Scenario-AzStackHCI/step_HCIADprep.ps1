
$tmppath = "c:\temp\" 
$logfile = "step_HCIADprep.log"
#create folder if it doesn't exist
if (!(Test-Path -Path $tmppath)) { mkdir $tmppath }
Start-Transcript "$tmppath\$logfile" -Append
"(step_HCIADPrep.ps1) was run at $(Get-Date)"

$adPrepCode = @"
# Prepare Active Directory for Azure Stack HCI, version 23H2 deployment 
# https://learn.microsoft.com/en-us/azure-stack/hci/deploy/deployment-prep-active-directory
# Creates OU (just 1 level i.e. 'OU=HCI') in existing OU path (i.e. 'DC=HCI00,DC=org') and adds user to OU if it does not exist (if it exists it will only give it permissions to the OU)
`$OU="OU=HCI,DC=HCI00,DC=org"
`$deployUserName = "asLCMUser"
`$deployUserPwd = "%YourPasswordHere%"

#Import-Module .\AsHciADArtifactsPreCreationTool.psm1
Install-PackageProvider -Name NuGet -confirm:$false -force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module AsHciADArtifactsPreCreationTool -Repository PSGallery -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted

`$securePwd = ConvertTo-SecureString "`$deployUserPwd" -AsPlainText -Force
`$credential = New-Object System.Management.Automation.PSCredential (`$deployUserName, `$securePwd)
New-HciAdObjectsPreCreation -AzureStackLCMUserCredential `$credential -AsHciOUName "`$OU"
"@

"outputting 'Prepare Active Directory for Azure Stack HCI, version 23H2 deployment'  to $tmppath\step_HCIADprep.ps1"
$adPrepCode | Out-File -FilePath "$tmppath\step_HCIADprep.ps1" -Force -Verbose

Stop-Transcript
