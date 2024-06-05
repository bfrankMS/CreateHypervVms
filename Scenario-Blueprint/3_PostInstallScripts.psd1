@{
    VM0 = @{
        vmPostInstallSteps = @(
            @{
                stepHeadline    = "Step0 - TimeStamp"           # Headline of the step - ! steps will be performed in alphabetical order !
                scriptFilePath  = "step_AddDateTimeToLog.ps1"   # Path to the script to be executed
                requiresRestart = $false                        # Does the step require a restart of the VM?
            }
            <#@{
                stepHeadline    = "Step1 - NextStep"
                scriptFilePath  = "step_AddDateTimeToLog.ps1"
                requiresRestart = $false
            }
            .
            .
            .
            #>
        )
    }
    VM1 = @{
        <#
        vmCopySteps = @(
            @{
                stepHeadline    = 'Copy something to the VM'
                sourcePath       = '.\copyIntoVM.txt'              # local (in this folder) archive to be copied to vm
                destPath        = 'c:\temp\copyIntoVM.txt'         # destination full path inside the vm
            } 
        )
        #>
        vmPostInstallSteps = @(
            @{
                stepHeadline    = "Step0 - TimeStamp"
                scriptFilePath  = "step_AddDateTimeToLog.ps1"
                requiresRestart = $false
            }
            @{
                stepHeadline    = "Step1 - Windows Update"
                scriptFilePath  = "step_DoWindowsUpdates.ps1"
                requiresRestart = $true
            }
        )
    }
}