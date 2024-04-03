param(
    [string] $externalAdapterName,
    [string] $internalAdapterName,
    [string] $externalAdapterCIDR,
    [string] $externalAdapterDG,
    [string] $externalAdapterDNS
)

$tmppath = "c:\temp"
$logfile = "PostInstallScripts.log"
#create folder if it doesn't exist
if (!(Test-Path -Path $tmppath)) { mkdir $tmppath }
Start-Transcript "$tmppath\$logfile" -Append
"(step_PrepareAdminBox.ps1) was run at $(Get-Date)"

#region Set Ext IP Address
    $externalAdapter = Get-NetAdapterAdvancedProperty | Where-Object { $_.DisplayValue -eq $externalAdapterName }
    $externalAdapterIP = $externalAdapterCIDR.Split('/')[0]
    $externalAdapterIPMask = $externalAdapterCIDR.Split('/')[1]
    Set-NetIPInterface -InterfaceAlias $externalAdapter.ifAlias -Dhcp Enabled -Verbose
    Start-Sleep -Seconds 3
    Set-NetIPInterface -InterfaceAlias $externalAdapter.ifAlias -Dhcp Disabled -Verbose
    New-NetIPAddress -InterfaceAlias $externalAdapter.ifAlias -IPAddress $externalAdapterIP -AddressFamily IPv4 -PrefixLength $externalAdapterIPMask -Verbose -DefaultGateway $externalAdapterDG
    Set-DnsClientServerAddress -InterfaceAlias $externalAdapter.ifAlias -ServerAddresses ($externalAdapterDNS)
    Start-Sleep -Seconds 3
#endregion

#region Allow RDP
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
#endregion

#region Install Windows Admin Center
    $WACInstallerUrl = "https://aka.ms/WACDownload"
    $InstallerPath = "$tmppath\WACInstaller.msi"
    
    # Download the installer
    try {
        $ErrorActionPreference = "Stop"
        "1st try to download WAC installer"
        [System.Net.WebClient]::DownloadFile($WACInstallerUrl, $InstallerPath)
    }
    catch {
        "2nd try to download WAC installer"
        [System.Net.WebClient]::DownloadFile($WACInstallerUrl, $InstallerPath)
    }
    
    # Install Windows Admin Center
    "Installing Windows Admin Center"
    Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$InstallerPath`" /qn /L*v $tmppath\WACInstall.log SME_PORT=443 SSL_CERTIFICATE_OPTION=generate" -Wait
    
    # Clean up the installer
    #Remove-Item -Path $InstallerPath
#endregion

#region Install RRAS feature
"Installing RRAS feature"
Install-WindowsFeature Routing -IncludeManagementTools -IncludeAllSubFeature -Verbose
Install-WindowsFeature RSAT-RemoteAccess-Mgmt -Verbose
# Configure RRAS for NAT
Install-RemoteAccess -VpnType RoutingOnly  -Verbose

# NAT configuration                 
$netshFile = @"
pushd routing ip nat
uninstall
install
set global tcptimeoutmins=1440 udptimeoutmins=1 loglevel=ERROR
add interface name="EXTERNAL" mode=FULL
add interface name="INTERNAL" mode=PRIVATE
popd
"@

$netshFile = $netshFile -replace "EXTERNAL",$externalAdapterName
$netshFile = $netshFile -replace "INTERNAL",$internalAdapterName

"Configuring RRAS"
$netshFile | Out-File -FilePath "$tmppath\netshfile.txt" -Encoding ascii 
Start-Process -FilePath netsh -ArgumentList  "-f $tmppath\netshfile.txt" -Wait -Verbose

Start-Process -FilePath sc -ArgumentList "config remoteaccess start=auto" -Wait -Verbose
Start-Process -FilePath net -ArgumentList "net start remoteaccess" -Wait -Verbose

#endregion

#region Install MMC tools
"Installing MMC tools"
Install-WindowsFeature -Name RSAT-Clustering -IncludeAllSubFeature -verbose
Install-WindowsFeature -Name RSAT-Hyper-V-Tools -IncludeAllSubFeature -verbose
#endregion

Stop-Transcript

