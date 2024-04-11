$tmppath = "c:\temp"
$logfile = "step_InstallHyperV.log"
#create folder if it doesn't exist
if (!(Test-Path -Path $tmppath)){mkdir $tmppath}
Start-Transcript "$tmppath\$logfile" -Append
"(step_InstallHyperV.ps1) was run at $(Get-Date)"

# Install Hyper-V
$os = Get-WmiObject -Class Win32_OperatingSystem
$os.Name
if ($os.Name -like "*Azure Stack HCI*") {
    Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Online" -All -norestart
} else {
    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools 
}

#enable RDP
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

#Add-VMNetworkAdapter -ManagementOS -Name vmswitch -SwitchName 'SetSwitch'
#New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceAlias 'vEthernet (vmswitch)'
#New-NetNAT -Name 'vmswitchNAT' -InternalIPInterfaceAddressPrefix 192.168.0.0/24

<#physicalhost
Get-VMNetworkAdapter -vmname '00-hci-1' -Name smb* | Set-VMNetworkAdapterVlan -Trunk -NativeVlanId 0 -AllowedVlanIdList 711-712
Get-VMNetworkAdapter -vmname '00-hci-2' -Name smb* | Set-VMNetworkAdapterVlan -Trunk -NativeVlanId 0 -AllowedVlanIdList 711-712

Get-VMNetworkAdapter -vmname '00-hci-1' -Name comp* | Set-VMNetworkAdapterVlan -Trunk -NativeVlanId 0 -AllowedVlanIdList 100-3000
Get-VMNetworkAdapter -vmname '00-hci-2' -Name comp* | Set-VMNetworkAdapterVlan -Trunk -NativeVlanId 0 -AllowedVlanIdList 100-3000

#>

<# inside the nested host
$SetSwitchName = "SetSwitch"

$SETAdapter1Name = "COMP1"
$SETAdapter2Name = "COMP2"
  
$StorageAdapter1Name = "SMB1"
$SMB1IP = "10.10.10.11"
$SMB1VLAN = 711
$StorageAdapter2Name = "SMB2"
$SMB2IP = "10.10.11.11"
$SMB2VLAN = 712


#Create the SET Switch
New-VMSwitch -Name "$SetSwitchName" -NetAdapterName $SETAdapter1Name, $SETAdapter2Name -EnableEmbeddedTeaming $true -AllowManagementOS $false -EnableIov $true


#region Configure The SMB Adapters
#SMB1
Set-NetIPInterface -InterfaceAlias $StorageAdapter1Name -Dhcp Enabled -Verbose
Start-Sleep 10
Set-NetIPInterface -InterfaceAlias $StorageAdapter1Name -Dhcp Disabled -Verbose
Start-Sleep 2
New-NetIPAddress -InterfaceAlias $StorageAdapter1Name -IPAddress $SMB1IP -AddressFamily IPv4 -PrefixLength 24 -Verbose
Start-Sleep 2
Disable-NetAdapterBinding -InterfaceAlias $StorageAdapter1Name -ComponentID ms_tcpip6
Set-DnsClient -InterfaceAlias $StorageAdapter1Name -RegisterThisConnectionsAddress $false
Set-NetAdapter -Name $StorageAdapter1Name -VlanID $SMB1VLAN -Confirm:$false
Set-NetAdapterAdvancedProperty -Name "$StorageAdapter1Name" -DisplayName "Jumbo Packet" -RegistryValue 9014
#Set-NetAdapterAdvancedProperty -Name "$StorageAdapter1Name" -DisplayName "R/RoCE Max Frame Size" -RegistryValue 4096
$StorageAdapter1WMIObjectName = "netconnectionid = '" + $StorageAdapter1Name + "'"
$StorageAdapter1WMINic = (Get-WmiObject Win32_NetworkAdapter -Filter "$StorageAdapter1WMIObjectName").GetRelated('Win32_NetworkAdapterConfiguration')
$StorageAdapter1WMINic.SetTcpipNetbios(2)
#Set-NetAdapterAdvancedProperty -Name $StorageAdapter1Name -DisplayName 'Dcbxmode' -DisplayValue 'Host in charge'
Start-Sleep 2

#SMB2
Set-NetIPInterface -InterfaceAlias $StorageAdapter2Name -Dhcp Enabled -Verbose
Start-Sleep 10
Set-NetIPInterface -InterfaceAlias $StorageAdapter2Name -Dhcp Disabled -Verbose
Start-Sleep 2
New-NetIPAddress -InterfaceAlias $StorageAdapter2Name -IPAddress $SMB2IP -AddressFamily IPv4 -PrefixLength 24 -Verbose
Start-Sleep 2
Disable-NetAdapterBinding -InterfaceAlias $StorageAdapter2Name -ComponentID ms_tcpip6
Set-DnsClient -InterfaceAlias $StorageAdapter2Name -RegisterThisConnectionsAddress $false
Set-NetAdapter -Name $StorageAdapter2Name -VlanID $SMB2VLAN -Confirm:$false
Set-NetAdapterAdvancedProperty -Name "$StorageAdapter2Name" -DisplayName "Jumbo Packet" -RegistryValue 9014
#Set-NetAdapterAdvancedProperty -Name "$StorageAdapter1Name" -DisplayName "R/RoCE Max Frame Size" -RegistryValue 4096
$StorageAdapter2WMIObjectName = "netconnectionid = '" + $StorageAdapter2Name + "'"
$StorageAdapter2WMINic = (Get-WmiObject Win32_NetworkAdapter -Filter "$StorageAdapter2WMIObjectName").GetRelated('Win32_NetworkAdapterConfiguration')
$StorageAdapter2WMINic.SetTcpipNetbios(2)
#Set-NetAdapterAdvancedProperty -Name $StorageAdapter2Name -DisplayName 'Dcbxmode' -DisplayValue 'Host in charge'
Start-Sleep 2
#endregion

#>



Stop-Transcript