##########################################################
# 
#   This script creates a bunch of Windows VMs based on a golden image on Hyper-v
#
##########################################################

# inspirations and alternatives.
# https://github.com/microsoft/MSLab
# https://github.com/BladeFireLight/WindowsImageTools/tree/master
# https://learn.microsoft.com/en-us/archive/blogs/virtual_pc_guy/script-image-factory-for-hyper-v
# http://www.altaro.com/hyper-v/creating-generation-2-disk-powershell/


# 1. Create a golden image and adjust these variables
$GoldenImage = "c:\.....\W2k22.vhdx"       # ??? path to a sysprepped virtual hard disk (UEFI i.e. Gen2 VMs) to be used as a golden image
$vmDirectoryPrefix = "c:\.....your VM storage....\AzStack"   # ??? generic path where the VMs will be created - each VM gets its subfolder

# 2. Provide a complex generic local admin pwd
$adminPassword = '....A complex PWD please.......'   # ??? use single quotes to avoid PS special chars interpretation problems (e.g. $ in pwd problems)

# 3. Navigate to the config files and adjust them to your needs
$currentPath = (Get-Location).Path
$vmConfig = Import-PowerShellDataFile $("$currentPath\1_VMs.psd1")
$vmUnattendConfig = Import-PowerShellDataFile $("$currentPath\2_UnattendSettings.psd1")
$vmPostInstallConfig = Import-PowerShellDataFile $("$currentPath\3_PostInstallScripts.psd1")

# Do not change anything below this line unless you know what you are doing
#   |
#   |
#   V

#region Test Settings
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
$testPaths = @(
    @{
        path         = $($GoldenImage)
        errormessage = "Golden image not found at $GoldenImage"
        abortscript  = $true
    }
    @{
        path         = $("$currentPath\1_VMs.psd1")
        errormessage = "Cannot find vmconfig in $("$currentPath\1_VMs.psd1")"
        abortscript  = $true
    }
    @{
        path         = $("$currentPath\2_UnattendSettings.psd1")
        errormessage = "Cannot find vmconfig in $("$currentPath\2_UnattendSettings.psd1")"
        abortscript  = $true
    }
    @{
        path         = $("$currentPath\3_PostInstallScripts.psd1")
        errormessage = "Unattend config file not found at $currentPath\2_UnattendSettings.psd1"
        abortscript  = $false
    }
)

#abort if any important files are missing
foreach ($testPath in $testPaths) {
    if (!(Test-Path $testPath.path)) {
        Write-Host $testPath.errormessage -ForegroundColor Red
        if ($testPath.abortscript) {
            Write-Host "Aborting script" -ForegroundColor Red
            if ($testPath.abortscript) { exit }
        }
    }
}
$vmSwitches = Get-VMSwitch
$vmSwitchesNames = @()
$totalVmMemory = [decimal]0
#gather vm settings
foreach ($vm in $($vmConfig.GetEnumerator() | Sort-Object Name)) {
    $vmNics = $vm.Value.vmNics 
    $totalVmMemory += $vm.Value.vmMemory  
    foreach ($vmNic in $($vmNics.GetEnumerator() | Sort-Object Name)) {
        $vmSwitchesNames += $($VMNic.Value.Switch)
    }
}
#abort if any defined switches are missing on host
$vmSwitchesNames = $vmSwitchesNames | Select-Object -Unique
if (!($null -eq $(Compare-Object -ReferenceObject $vmSwitches.Name -DifferenceObject $vmSwitchesNames | Where-Object SideIndicator -EQ '=>'))) {
    Write-Host "...following Hyper-V Switches are in 1_VM.psd1 but not on available on Host `n" -ForegroundColor Red
    $(Compare-Object -ReferenceObject $vmSwitches.Name -DifferenceObject $vmSwitchesNames | Where-Object SideIndicator -EQ '=>')
    exit
}
#abort if not enough memory available on host to start all VMs
$freeRAMOnHost = [decimal](((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory) * 1kB - 1GB)
if ([decimal]$totalVmMemory -gt $freeRAMOnHost) {
    Write-Host "...not enough free vm memory (required: $($totalVmMemory/1GB)GB) on host (available: $([system.math]::round($($freeRAMOnHost/1GB),2))GB)...aborting" -ForegroundColor Red
    "exit"
}

#abort if VMs are already created
foreach ($vm in $($vmConfig.GetEnumerator() | Sort-Object Name)) {
    $vmName = $vm.Value.vmName
    if (Get-VM $vmName -ErrorAction SilentlyContinue) {
        Write-Host "...VM $vmName already found on host...aborting" -ForegroundColor Red
        exit
    }
}
#abort if directories are not empty
foreach ($vm in $($vmConfig.GetEnumerator() | Sort-Object Name)) {
    $vmName = $vm.Value.vmName

     if (!([System.String]::IsNullOrEmpty($vm.Value.vmPath))) {
        $vmDirectory = $vm.Value.vmPath + "\" + $vmName
    }
    else {
        $vmDirectory = $vmDirectoryPrefix + "\" + $vmName #+ "{0:00}" -f $i  #e.g. 'D:\VMs\TN01...', 02, 03,...
    }

    if ((Get-ChildItem -Path $vmDirectory -Recurse | Measure-Object).Count -gt 0) {
        Write-Host "...directory $vmDirectory is not empty...aborting" -ForegroundColor Red
        exit
    }
}
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = $oldErrorActionPreference
#endregion  

#region Sysprep unattend XML
$unattendSource = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>*</ComputerName>
            <ProductKey>Key</ProductKey> 
            <RegisteredOrganization>Organization</RegisteredOrganization>
            <RegisteredOwner>Owner</RegisteredOwner>
            <TimeZone>W. Europe Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-IE-ESC" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <IEHardenAdmin>false</IEHardenAdmin>
        </component>
        <component name="Microsoft-Windows-ErrorReportingCore" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DisableWER>1</DisableWER>
        </component>
        <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <fDenyTSConnections>false</fDenyTSConnections>
        </component>
        <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Interfaces>
                <Interface wcm:action="add">
                    <Ipv4Settings>
                        <DhcpEnabled>false</DhcpEnabled>
                    </Ipv4Settings>
                    <UnicastIpAddresses>
                        <IpAddress wcm:action="add" wcm:keyValue="1">127.0.0.1/24</IpAddress>
                    </UnicastIpAddresses>
                    <Identifier>MAC</Identifier>
                    <Routes>
                        <Route wcm:action="add">
                            <Identifier>1</Identifier>
                            <Prefix>0.0.0.0/0</Prefix>
                            <NextHopAddress>127.0.0.1</NextHopAddress>
                        </Route>
                    </Routes>
                </Interface>
            </Interfaces>
        </component>
        <component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Interfaces>
                <Interface wcm:action="add">
                    <DNSServerSearchOrder>
                        <IpAddress wcm:action="add" wcm:keyValue="1">127.0.0.1</IpAddress>
                    </DNSServerSearchOrder>
                    <Identifier>MAC</Identifier>
                </Interface>
            </Interfaces>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>powershell.exe -command &quot;`$HVNicNames = Get-NetAdapterAdvancedProperty -DisplayName &apos;Hyper-V Network Adapter Name&apos;;foreach(`$HVNicName in `$HVNicNames){ Rename-NetAdapter -Name `$HVNicName.Name -NewName `$HVNicName.DisplayValue}&quot;</CommandLine>
                    <Order>1</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>powershell.exe -command &quot;Remove-Item -Path &apos;C:\unattend.xml&apos; -Force&quot;</CommandLine>
                    <Order>2</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>logoff</CommandLine>
                    <Order>3</Order>
                    <RequiresUserInput>false</RequiresUserInput>
            </SynchronousCommand>
            </FirstLogonCommands>
            <AutoLogon>
                <Username>Administrator</Username>
                <Enabled>true</Enabled>
                <LogonCount>1</LogonCount>
                <Password>
                    <Value>password</Value>
                    <PlainText>true</PlainText>
                </Password>
            </AutoLogon>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>password</Value>
                    <PlainText>True</PlainText>
                </AdministratorPassword>
            </UserAccounts>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-us</InputLocale>
            <SystemLocale>en-us</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UILanguageFallback>en-us</UILanguageFallback>
            <UserLocale>en-us</UserLocale>
        </component>
    </settings>
</unattend>
"@
#endregion

#region Helper functions
function Get-UnattendSection {
    param
    (
        [string] $pass, 
        [string] $component, 
        [xml] $unattend
    ); 
                
    # Helper function that returns one component chunk from the Unattend XML data structure
    return $Unattend.unattend.settings | Where-Object pass -EQ $pass `
    | Select-Object -ExpandProperty component `
    | Where-Object name -EQ $component;
}
function Clear-UnDefinedChildUnattendSections {
    param (
        [string] $pass, 
        [string] $component,
        [string] $child, 
        [xml] $unattend
    )
    $childs = ($unattend.unattend.settings  | Where-Object pass -EQ $pass).component | Where-Object name -EQ $component
    $childs.RemoveChild($childs[$child]) | Out-Null
}
function Clear-UnDefinedUnattendSections {
    param (
        [string] $pass, 
        [string] $component,
        [xml] $unattend
    )
    $components = ($unattend.unattend.settings  | Where-Object pass -EQ $pass)
    $childToDelete = $components.ChildNodes | Where-Object name -EQ $component
    $components.RemoveChild($childToDelete) | Out-Null
}
function Wait-ForPSDirect([string]$VMName, $cred) {
   
    #make sure VM is up and running
    while ((Get-VM -Name $VMName | Select-Object PrimaryOperationalStatus).tolower() -ne 'ok') { Start-Sleep -Seconds 5 }

    #make sure integration component heartbeat is responsive
    while ((Get-VMIntegrationService $VMName -Name 'Heartbeat' -Credential $cred).PrimaryStatusDescription.tolower() -ne 'OK') { Start-Sleep -Seconds 5 }

    #make sure VM can take remote commands
    while ((Invoke-Command -VMName $VMName -Credential $cred { 'Test' } -ea SilentlyContinue) -ne 'Test') { Start-Sleep -Seconds 5 }
   
    #make sure nobody is logged at the console (unattend)
    $checkForConsoleUser = {
        $consoleuser = &query user | Select-String 'console';
        [System.string]::IsNullOrEmpty($consoleuser)
    }
    while ((Invoke-Command -VMName $VMName -Credential $cred $checkForConsoleUser -ea SilentlyContinue) -ne $true) { Start-Sleep -Seconds 5 }
}
#endregion

# Test the config files or abort script
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'silentlycontinue'
if (Test-Settings -eq $false) { exit }
$ErrorActionPreference = $oldErrorActionPreference

$starttime = Get-Date
"Starting at {0:dd-MM-yyyy HH:mm:ss}" -f $(Get-Date)

#region Create A Bunch Of VMs
"`n*******************"
"* Creation Of VMs *"
"*******************`n"
foreach ($vm in $($vmConfig.GetEnumerator() | Sort-Object Name)) {
    $vmProcCount = $vm.Value.vmProcCount                                                                                                                                                                              
    $vmNics = $vm.Value.vmNics                                                                                                                                                                                  
    $vmName = $vm.Value.vmName
    $vmMemory = $vm.Value.vmMemory                                                                                                                                                                                 
    $vmGeneration = $vm.Value.vmGeneration                                                                                                                                                                             
    $vmAutomaticStopAction = $vm.Value.vmAutomaticStopAction
    $vmDataDisks = $vm.Value.vmDataDisks

    "`n======Creating: {0}======" -f $vmName 
    if (!([System.String]::IsNullOrEmpty($vm.Value.vmPath))) {
        $vmDirectory = $vm.Value.vmPath
        "...using vm specific path ($vmDirectory)..."
    }
    else {
        $vmDirectory = $vmDirectoryPrefix #+ "{0:00}" -f $i  #e.g. 'D:\VMs\TN01...', 02, 03,...
        "...using generic path ($vmDirectory)..."
    }

    New-Item -Path $vmDirectory -ItemType Directory -ErrorAction SilentlyContinue
    New-VM -Name $vmName -MemoryStartupBytes $vmMemory -NoVHD  -Path $vmDirectory -Generation $vmGeneration | Set-VM -ProcessorCount $vmProcCount  -AutomaticStopAction $vmAutomaticStopAction 

    #region allow for nested virtualization
    if ($vm.Value.ExposeVirtualizationExtensions)
    {
        "...enabling nested virtualization..."
        Set-VMProcessor -VMName $vmName -ExposeVirtualizationExtensions $true
        Start-Sleep -Seconds 5
    }
    #endregion

    #region VM's Network Adapters
    Get-VMNetworkAdapter -VMName $vmName | Remove-VMNetworkAdapter; Start-Sleep -Seconds 1
    #then add the desired ones in a sorted alphabetical order - the 1st one will be the one with the static MAC -> hence receive the static IP configured.
    foreach ($vmNic in $($vmNics.GetEnumerator() | Sort-Object Name)) {
        #when first adapter
        if ($($vmNic.Name) -eq $($vmNics.Keys | Sort-Object | Select-Object -First 1)) {
            #save MAC for 1st adapter for unattend later
            $staticMacAddress = "00155D{0:X2}{1:X2}{2:X2}" -f $(Get-Random -Minimum 1 -Maximum 255 -SetSeed $([int32][system.datetime]::Now.Millisecond)), $(Start-Sleep -Millisecond 5; Get-Random -Minimum 10 -Maximum 255 -SetSeed $([int32][system.datetime]::Now.Millisecond)), $(Start-Sleep -Millisecond 5; Get-Random -Minimum 3 -Maximum 255 -SetSeed $([int32][system.datetime]::Now.Millisecond))
            "...attaching nic $($VMNic.Name) with static MAC {0} (to receive unattend IP settings)" -f $staticMacAddress
            Add-VMNetworkAdapter -VMName $VmName -SwitchName $($VMNic.Value.Switch) -Name $($VMNic.Name) -DeviceNaming on -StaticMacAddress $staticMacAddress.Trim() 
            $MACAddress = $staticMacAddress -split '([0-9a-f]{2})' -ne '' -join '-'
        }
        else {
            "...attaching nic $($VMNic.Name)"
            Add-VMNetworkAdapter -VMName $VmName -SwitchName $($VMNic.Value.Switch) -Name $($VMNic.Name) -DeviceNaming on
        }
        Start-Sleep -Milliseconds 500

        if ($VMNic.Value.VLANID -ne '') {
            $internalVLANID = $VMNic.Value.VLANID.Replace("xx", $("{0:00}" -f $i))    #e.g. 1101,1102,...
            #"NIC: {0}   Switch: {1}   VLANID: {2}" -f $VMNic.Name, $VMNic.Value.Switch, $internalVLANID
            Set-VMNetworkAdapterVlan -VMName $vmName -VMNetworkAdapterName $($VMNic.Name) -Access -VlanId $internalVLANID
        }
        else {
            #"NIC: {0}   Switch: {1}" -f $VMNic.Name, $VMNic.Value.Switch
        }

        if ($VMNic.Value.MacAddressSpoofing) {
            Set-VMNetworkAdapter -VMName $VmName -Name $($VMNic.Name) -MacAddressSpoofing On
        }

    } 
    #endregion


    $vhdDirectory = $vmDirectory + "\" + $vmName + "\Virtual Hard Disks"
    New-Item -Path $vhdDirectory -ErrorAction SilentlyContinue -ItemType Directory | Out-Null

    if (!([System.String]::IsNullOrEmpty($vm.Value.GoldenImagePath))) {
        $GoldenImagePath = $vm.Value.GoldenImagePath
        $OSVHD = $vhdDirectory + "\" + $(Split-Path -Path $GoldenImagePath -Leaf)
        "...copy vm specific OS disk to $OSVHD"
        Copy-Item -Path $GoldenImagePath -Destination $OSVHD -ErrorAction Stop #-Verbose
    }
    else {
    $OSVHD = $vhdDirectory + "\" + $(Split-Path -Path $GoldenImage -Leaf)
    "...copy generic OS disk to $OSVHD"
    Copy-Item -Path $GoldenImage -Destination $OSVHD -ErrorAction Stop #-Verbose
}

    "...mounting OS disk $OSVHD"
    $OSVolumes = Mount-VHD -Path $OSVHD -Passthru | Get-Disk | Get-Partition | Get-Volume
    foreach ($Drive in $OSVolumes) {
        if (($Drive.DriveLetter -ne '') -and ($Null -ne $Drive.DriveLetter)) {
                
            if ($null -ne $vmUnattendConfig[$vm.Name]) {
                # unattend for vm found? if yes process it! 
                "...creating unattend.xml for vm $($vm.Name)"
                # Reload template - clone is necessary as PowerShell thinks this is a "complex" object
                $unattend = $unattendSource.Clone();
                       
                # Customize unattend XML
                Get-UnattendSection 'specialize' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.ComputerName = $vmName };
                Get-UnattendSection 'specialize' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.RegisteredOrganization = $vmUnattendConfig[$vm.Name].Organization };
                Get-UnattendSection 'specialize' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.RegisteredOwner = $vmUnattendConfig[$vm.Name].Owner };
                Get-UnattendSection 'specialize' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.TimeZone = $vmUnattendConfig[$vm.Name].Timezone };
                
                #vm has specific admin password?
                if (!([System.String]::IsNullOrEmpty($vmUnattendConfig[$vm.Name].'adminPassword'))) {
                    Get-UnattendSection 'oobeSystem' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.UserAccounts.AdministratorPassword.Value = $vmUnattendConfig[$vm.Name].'adminPassword' };
                    Get-UnattendSection 'oobeSystem' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.AutoLogon.Password.Value = $vmUnattendConfig[$vm.Name].'adminPassword' };
                }
                else {
                    Get-UnattendSection 'oobeSystem' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.UserAccounts.AdministratorPassword.Value = $adminPassword };
                    Get-UnattendSection 'oobeSystem' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.AutoLogon.Password.Value = $adminPassword };
                }
                #vm has specific product key?
                if (!([System.String]::IsNullOrEmpty($vmUnattendConfig[$vm.Name].'ProductKey'))) {
                    Get-UnattendSection 'specialize' 'Microsoft-Windows-Shell-Setup' $unattend | ForEach-Object { $_.ProductKey = $vmUnattendConfig[$vm.Name].ProductKey };
                }
                else {
                    Clear-UnDefinedChildUnattendSections 'specialize' 'Microsoft-Windows-Shell-Setup' 'ProductKey' $unattend
                }
                #handling static or dynamic IP
                if (!([System.String]::IsNullOrEmpty($vmUnattendConfig[$vm.Name].'IPAddress'))) {
                    Get-UnattendSection 'specialize' 'Microsoft-Windows-TCPIP' $unattend | ForEach-Object { $_.Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $vmUnattendConfig[$vm.Name].IPAddress + "/" + $($vmUnattendConfig[$vm.Name].IPMask) };

                    if (!([System.String]::IsNullOrEmpty($vmUnattendConfig[$vm.Name].IPGateway))){
                    Get-UnattendSection 'specialize' 'Microsoft-Windows-TCPIP' $unattend | ForEach-Object { $_.Interfaces.Interface.Routes.Route.NextHopAddress = $vmUnattendConfig[$vm.Name].IPGateway };
                    }else {
                        (Get-UnattendSection 'specialize' 'Microsoft-Windows-TCPIP' $unattend | ForEach-Object { $_.Interfaces.Interface.Routes} ).RemoveAll()
                    }
                    
                    Get-UnattendSection 'specialize' 'Microsoft-Windows-DNS-Client' $unattend | ForEach-Object { $_.Interfaces.Interface.DNSServerSearchOrder.IpAddress.'#text' = $vmUnattendConfig[$vm.Name].DNSIP };
                    Get-UnattendSection 'specialize' 'Microsoft-Windows-TCPIP' $unattend | ForEach-Object { $_.Interfaces.Interface.Identifier = $MACAddress };
                    Get-UnattendSection 'specialize' 'Microsoft-Windows-DNS-Client' $unattend | ForEach-Object { $_.Interfaces.Interface.Identifier = $MACAddress };
                }
                else {
                    Clear-UnDefinedUnattendSections 'specialize' 'Microsoft-Windows-TCPIP' $unattend
                    Clear-UnDefinedUnattendSections 'specialize' 'Microsoft-Windows-DNS-Client' $unattend
                }
                Get-UnattendSection 'oobeSystem' 'Microsoft-Windows-International-Core' $unattend | ForEach-Object { $_.InputLocale = $vmUnattendConfig[$vm.Name].InputLocale };
                Get-UnattendSection 'oobeSystem' 'Microsoft-Windows-International-Core' $unattend | ForEach-Object { $_.SystemLocale = $vmUnattendConfig[$vm.Name].SystemLocale };
                Get-UnattendSection 'oobeSystem' 'Microsoft-Windows-International-Core' $unattend | ForEach-Object { $_.UserLocale = $vmUnattendConfig[$vm.Name].UserLocale };

               # Write it out to disk
                $UnattendFile = $($Drive.DriveLetter + ':\Unattend.xml')
                $unattend.Save($UnattendFile);
            }

            if ($(Test-Path "$currentPath\$($vm.Name)") -eq $true) {
                #is there any folder named like the VMs in the VMs.psd1 e.g. VM0,VM1... if so copy contents into VM
                $destination = $($Drive.DriveLetter + ':\temp')
                New-Item -Path $destination -ErrorAction SilentlyContinue -ItemType Directory
                Copy-Item -Path "$currentPath\$($vm.Name)\*" -Destination $destination -Verbose -Recurse
            }
        }
    }
    Dismount-VHD -Path $OSVHD
    "...attaching OS disk to VM"
    Add-VMHardDiskDrive -VMName $VmName -Path $OSVHD

    foreach ($vmDataDisk in $vmDataDisks) {
       "...attaching data disk $($vmDataDisk.DiskName) with size $($vmDataDisk.DiskSize)"
        $DiskPath = $vhdDirectory + "\" + $($vmDataDisk.DiskName)
        New-VHD -Path $DiskPath -SizeBytes $([uint64]$($vmDataDisk.DiskSize)) -Dynamic
        Add-VMHardDiskDrive -VMName $VmName -Path $DiskPath
    }

    #make VM boot from first disk
    Set-VMFirmware -VMName $vmName -BootOrder $((Get-VMFirmware $vmName).BootOrder | Where-Object Device -Like "*location 0*")

    Start-Sleep -Seconds 2
    Start-VM $vmName 
    "======End Creating: {0}======`n" -f $vmName
}
#endregion

#region Perform Post Installation Steps
"`n***************************"
"* Performing Post Install *"
"***************************`n"

$postInstallVMs = ($vmPostInstallConfig.GetEnumerator() | Sort-Object Name)

foreach ($postInstallVM in $postInstallVMs) {
    $vmName = ($vmConfig.GetEnumerator() | Where-Object name -EQ $($postInstallVM.Name)).value.vmname
    "`n======PostInstall: {0}======" -f $vmName 
    "Wait until VM {0} is up and responsive" -f $vmName

    if (!([System.String]::IsNullOrEmpty($vmUnattendConfig[$postInstallVM.Name].'adminPassword'))) {
        "...using vm specific credential..."
        $UserPassword = ConvertTo-SecureString $vmUnattendConfig[$postInstallVM.Name].'adminPassword' -AsPlainText -Force 
        $UserCredential = New-Object System.Management.Automation.PSCredential (".\Administrator", $UserPassword)  #use the dot '.' for local admin especially if you are using DC joined vms.
    }
    else {
        "...using vm `$adminPassword credential..."
        $UserPassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force 
        $UserCredential = New-Object System.Management.Automation.PSCredential (".\Administrator", $UserPassword)  #use the dot '.' for local admin especially if you are using DC joined vms.
    }

    Wait-ForPSDirect $vmName $UserCredential # wait till VM is up and responsive
        
    foreach ($item in $($postInstallVM.value.vmPostInstallSteps)) {
        if (!([string]::IsNullOrWhiteSpace($item.scriptArgumentList))) {
            $invokeParameters = @{
                VMName       = $vmName
                Credential   = $UserCredential
                ArgumentList = $item.scriptArgumentList
                FilePath     = $item.scriptFilePath
            }
        }
        else {
            $invokeParameters = @{
                VMName     = $vmName
                Credential = $UserCredential
                FilePath   = $item.scriptFilePath
            }
        }

        "...running action: '{0}'" -f $item.stepHeadline
        Invoke-Command @invokeParameters 

        #restart required?
        if ($item.requiresRestart -eq $true) { 
            "...rebooting VM {0}" -f $vmName
            Stop-VM $vmName
            do {
                Start-Sleep 3
                "...waiting..." -f $vmName
            }
            until ((Get-VM $vmName).State -eq 'Off')
            Start-VM $vmName
            "...starting VM {0}" -f $vmName
            "...waiting until VM {0} is up and responsive" -f $vmName
            Wait-ForPSDirect $vmName $UserCredential # wait till VM is up and responsive
        }
        "...end of action: '{0}'" -f $item.stepHeadline
    }
    "======End: {0}======`n" -f $vmName 
}
#endregion

#region Remove Static MAC from VMs (as it was used for unattend ip assignment)
"`n******************************"
"* Remove Static MAC from VMs *"
"******************************`n"
foreach ($vm in $($vmConfig.GetEnumerator() | Sort-Object Name)) {
    $vmName = $vm.Value.vmName
    $adapter = Get-VMNetworkAdapter -VMName $vmName | Where-Object DynamicMacAddressEnabled -EQ $false
    if (!($null -eq $adapter)) {
        "...waiting until VM {0} is up and responsive" -f $vmName
        if (!([System.String]::IsNullOrEmpty($vmUnattendConfig[$vm.key].'adminPassword'))) {
            "...using vm specific credential..."
            $UserPassword = ConvertTo-SecureString $vmUnattendConfig[$vm.key].'adminPassword' -AsPlainText -Force 
            $UserCredential = New-Object System.Management.Automation.PSCredential (".\Administrator", $UserPassword)  #use the dot '.' for local admin especially if you are using DC joined vms.
        }
        else {
            "...using vm `$adminPassword credential..."
            $UserPassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force 
            $UserCredential = New-Object System.Management.Automation.PSCredential (".\Administrator", $UserPassword)  #use the dot '.' for local admin especially if you are using DC joined vms.
        }
        Wait-ForPSDirect $vmName $UserCredential # wait till VM is up and responsive
        "...stopping $vmName"
        Stop-VM $vmName
        do {
            Start-Sleep 3
            "...wait..." -f $vmName
        }
        until ((Get-VM $vmName).State -eq 'Off')
        $msvm_VirtualSystemManagementService = Microsoft.PowerShell.Management\Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService
        $msvm_SyntheticEthernetPortSettingData = Microsoft.PowerShell.Management\Get-WmiObject -Namespace root\virtualization\v2 -Class "Msvm_SyntheticEthernetPortSettingData" | Where-Object { $_.instanceID -eq $adapter.id }
        $msvm_SyntheticEthernetPortSettingData.StaticMacAddress = $false
        $msvm_SyntheticEthernetPortSettingData.Address = ""
        $msvm_VirtualSystemManagementService.ModifyResourceSettings($msvm_SyntheticEthernetPortSettingData.GetText(2)) | Out-Null
        "...dynamic MAC address is set on VM: $vmName"
    }
    else {
        "...all good for $vmName"
    }
}
#endregion
"******************************`n"
"Finished at {0:dd-MM-yyyy HH:mm:ss}" -f $(Get-Date)
"Elapsed time: {0:dd'dy:'hh'hr:'mm'min:'ss'sec'}" -f $((Get-Date) - $starttime)

$startvms = Read-Host -Prompt "Start all VMs? (Y/N)" 
if ($startvms.tolower() -eq 'y') {
    foreach ($vm in $($vmConfig.GetEnumerator() | Sort-Object Name)) {
        $vmName = $vm.Value.vmName
        "...starting $vmName"
        Start-VM $vmName
    }
}