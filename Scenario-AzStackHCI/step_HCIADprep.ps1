$tmppath = "c:\temp"

#create folder if it doesn't exist
if (!(Test-Path -Path $tmppath)){mkdir $tmppath}


$adPrepCode = @"
# Prepare Active Directory for Azure Stack HCI, version 23H2 deployment 
# https://learn.microsoft.com/en-us/azure-stack/hci/deploy/deployment-prep-active-directory

`$OU="OU=HCI,DC=HCI00,DC=org"
`$serverList = @("00-HCI-1","00-HCI-2")
`$domainFQDN = "hci00.org"
`$asHciClusterName = "HCInest"
`$asHciDeploymentPrefix = "hci"
`$deployUserName = "asLCMUser"
`$deployUserPwd = "%YourPasswordHere%"

#Import-Module .\AsHciADArtifactsPreCreationTool.psm1
Install-Module AsHciADArtifactsPreCreationTool -Repository PSGallery -Force

`$securePwd = ConvertTo-SecureString "`$deployUserPwd" -AsPlainText -Force
`$credential = New-Object System.Management.Automation.PSCredential (`$deployUserName, `$securePwd)
New-HciAdObjectsPreCreation -Deploy -AzureStackLCMUserCredential `$credential -AsHciOUName "`$OU" -AsHciPhysicalNodeList `$serverList  -DomainFQDN "`$domainFQDN" -AsHciClusterName "`$asHciClusterName" -AsHciDeploymentPrefix "`$asHciDeploymentPrefix"
"@

"outputting 'Prepare Active Directory for Azure Stack HCI, version 23H2 deployment'  to $tmppath\step_HCIADprep.ps1"
$adPrepCode | Out-File -FilePath "$tmppath\step_HCIADprep.ps1" -Force

