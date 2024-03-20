#this is the scriptblock to be run on the VM
param(
    [string] $Domain,
    [string] $User,
    [string] $Password
)
    
$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -Force }
            
#write a log file with the same name of the script
Start-Transcript "$tmpDir\PostInstallScripts.log"
            
"(step_JoinDomain.ps1) was run at $(Get-Date)"
            
#open Firewall for RDP
Enable-NetFirewallRule -DisplayName 'Remote Desktop*'

#do domain join
Start-Sleep 5
$SecurePassword = ConvertTo-SecureString "$Password" -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$Domain\$User", $SecurePassword
#keep old computername
Add-Computer -ComputerName localhost -DomainName $Domain -Credential $credential

#remove Unattend File.
Remove-Item 'c:\unattend.xml' -Force

#enable-ping
Get-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" | Enable-NetFirewallRule

#Install Latest Nuget Package Provider
#Install-PackageProvider Nuget –force –verbose
            
#set-psrepository -Name PSGallery -installationpolicy trusted 
#Install-Module Az -Force

Stop-Transcript