param(
    [Parameter(Mandatory=$True,Position=1)]
    [string] $adminUsername,

    [Parameter(Mandatory=$True,Position=2)]
    [string] $adminPassword
)

$tmppath = "c:\temp"
$logfile = "step_AzLocalAdmin.log"
#create folder if it doesn't exist
if (!(Test-Path -Path $tmppath)){mkdir $tmppath}
Start-Transcript "$tmppath\$logfile" -Append
"(step_AzLocalAdmin.ps1) was run at $(Get-Date)"

# Create a local admin account
"Creating a local admin account"
$securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
New-LocalUser -Name $adminUsername -Password $securePassword -FullName "Azure Stack HCI Admin" -Description "Local Admin Account" -AccountNeverExpires -PasswordNeverExpires -Verbose
Add-LocalGroupMember -Group "Administrators" -Member $adminUsername -Verbose


Stop-Transcript