@{
    VM0 = @{                                            # VM0 is the first VM - do not change this name
        ComputerName  = 'Test-N1'                       # computer name in the OS
        Organization  = 'myavd'                         # organization name in the OS
        Owner         = 'myavd'                         
        #adminPassword = '???'                          # (optional) password for the local admin account - if not set, the generic password $adminPassword from CreateHyperVVM.ps1 will be used
        Timezone      = 'W. Europe Standard Time'       # Timezone in OS you can do (PShell) to find yours  "get-timezone -ListAvailable | out-gridview -OutputMode Single | Select-Object ID"
        InputLocale   = 'de-DE'                         # Keyboard layout in OS
        SystemLocale  = 'en-US'                         # System locale in OS (sorting, etc.)
        UserLocale    = 'en-US'                         # User locale in OS (date, time, etc.)
        #ProductKey    = 'W3GNR-8DDXR-2TFRP-H8P33-DV9BG' # (optional) Product Key e.g. AVMA Key Windows Server 2022 Datacenter - https://learn.microsoft.com/en-us/windows-server/get-started/automatic-vm-activation
                                                        # when used the Product key needs to fit to the golden image!!!
        IPAddress     = "172.31.2.11"                   # (optional) static IP address to be assigned to the first NIC (alphabetical order in 1_VMs.psd1) - if not set, the IP address will be assigned by DHCP
        IPMask        = "16"                            # (required when IPAddress is used) subnet mask for the static IP address
        IPGateway     = "172.31.0.1"                    # (required when IPAddress is used) default gateway for the static IP address
        DNSIP         = "172.31.0.2"                    # (required when IPAddress is used) DNS server for the static IP address
    }
    VM1 = @{                                            # VM1 is the second VM - do not change this name
        ComputerName = 'Test-N2'
        Organization = 'myavd'
        Owner        = 'myavd'
        Timezone     = 'W. Europe Standard Time'
        InputLocale  = 'de-DE'
        SystemLocale = 'en-US'
        UserLocale   = 'en-US'
    }
    <#...#>
}
        