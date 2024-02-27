#don't touch at first deployment this should work and is behind a NAT so should not conflict with your local network.
@{
    VM0 = @{                                            # VM0 is the first VM - do not change this name
        ComputerName  = '00-DC-1'                       # computer name in the OS
        Organization  = 'myavd'                         # organization name in the OS
        Owner         = 'myavd'                         
        Timezone      = 'W. Europe Standard Time'       # ??? Timezone in OS you can do (PShell) to find yours  "get-timezone -ListAvailable | out-gridview -OutputMode Single | Select-Object ID"
        InputLocale   = 'de-DE'                         # ??? Keyboard layout in OS
        SystemLocale  = 'en-US'                         # System locale in OS (sorting, etc.)
        UserLocale    = 'en-US'                         # User locale in OS (date, time, etc.)
        IPAddress     = "192.168.0.1"                   # (optional) static IP address to be assigned to the first NIC (alphabetical order in 1_VMs.psd1) - if not set, the IP address will be assigned by DHCP
        IPMask        = "24"                            # (required when IPAddress is used) subnet mask for the static IP address
        IPGateway     = ""                              # (required when IPAddress is used) default gateway for the static IP address
        DNSIP         = "127.0.0.1"                     # (required when IPAddress is used) DNS server for the static IP address
    }
    VM1 = @{                                            # VM1 is the second VM - do not change this name
        ComputerName = '00-HCI-1'
        Organization = 'myavd'
        Owner        = 'myavd'
        Timezone     = 'W. Europe Standard Time'
        InputLocale  = 'de-DE'
        SystemLocale = 'en-US'
        UserLocale   = 'en-US'
        IPAddress     = "192.168.0.2"                 # (optional) static IP address to be assigned to the first NIC (alphabetical order in 1_VMs.psd1) - if not set, the IP address will be assigned by DHCP
        IPMask        = "24"                            # (required when IPAddress is used) subnet mask for the static IP address
        IPGateway     = "192.168.0.1"                    # (required when IPAddress is used) default gateway for the static IP address
        DNSIP         = "192.168.0.1"                 # (required when IPAddress is used) DNS server for the static IP address
    }
    VM2 = @{                                            
        ComputerName = '00-HCI-2'
        Organization = 'myavd'
        Owner        = 'myavd'
        Timezone     = 'W. Europe Standard Time'
        InputLocale  = 'de-DE'
        SystemLocale = 'en-US'
        UserLocale   = 'en-US'
        IPAddress     = "192.168.0.3"                 
        IPMask        = "24"                            
        IPGateway     = "192.168.0.1"                    
        DNSIP         = "192.168.0.1"                 
    }
}
        