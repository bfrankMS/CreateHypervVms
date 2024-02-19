# CreateHypervVms is to create Windows VMs on Hyper-V using PowerShell

>Warning: Use at you own risk. No liabilities. Although the script checks i.e. should not overwrite stuff I don't guarantee. Make sure you have a backup.

## Why? Use cases: 
You like PowerShell and are using Hyper-V and maybe need to:...
- ...create a lot of VMs.
- ...have a re-playable solution (e.g. Lab / Demo / Education environments)
- ...do a zero touch deployment and require automation
- ...bake your knowledge into script not screenshots.  
**--> then you should continue reading.**

## What it does - use cases
This set of scripts will create VMs on Hyper-V based on a golden image (i.e. sysprepped .vhdx) with the specific settings that you predefine in PShell config files.
- ...VMs will be created with the size, name, # of network adapters, # disks on Hyper-V how you define [1_VM.psd1](./1_VMs.psd1)
- ...Each VM gets its own configuration using unattend.xml - how you specify [2_UnattendSettings.psd1](./2_UnattendSettings.psd1)
- ...After the OS is installed you can define a set of post install PShell scripts to be run to custimize each individual VM [3_PostInstallScripts.psd1](./3_PostInstallScripts.psd1)  
**-->take this repo as a blueprint and adjust to your needs.**

## Requirements
OS: Windows Server 2016, Windows Server 2019, Windows Server 2022, Azure Stack HCI (22H2, 23H2)
Components: Hyper-V with corresponding PowerShell module.

Works either launched locally or using PS remoting.

## How to use it.
[![CreateHypervVMs on YTube](https://img.youtube.com/vi/A_zNSNHOKJU/0.jpg)](https://www.youtube.com/watch?v=A_zNSNHOKJU)
1. Copy this repositories contents to your Hyper-V system - e.g. c:\temp
2. Place a sysprep'ed .vhdx file containing the Windows OS you want to deploy into a folder.
3. Adjust the *$GoldenImage* variable in your copy of the [CreateHypervVms.ps1](./CreateHypervVms.ps1) file to match the path from step 2.
```c#
# 1. Create a golden image and adjust these variables
$GoldenImage = "c:\images\W2k22.vhdx"       # path to a sysprepped virtual hard disk (UEFI i.e. Gen2 VMs) to be used as a golden image
```
4. Make the *$vmDirectoryPrefix* variable of your copy of *CreateHypervVms.ps1* point to the VMs final path destination.
```c#
$vmDirectoryPrefix = "c:\ClusterStorage\CSV1\createvms"   # generic path where the VMs will be created - each VM gets its subfolder
```
5. Choose a complex default password for your *$adminPassword* variable of your copy of *CreateHypervVms.ps1*
```c#
# Provide a complex generic local admin pwd
$adminPassword = 'some0815pwd!'   # use single quotes to avoid PS special chars interpretation problems (e.g. $ in pwd problems)
```
6. Define the **Hyper-V details** of the VMs to create by **modifying your copy** of [1_VMs.psd1](./1_VMs.psd1). Open the file in a PowerShell scripting editor and read the comments.
7. Define the **OS details** of the VMs by modifying your copy of [2_UnattendSettings.psd1](./2_UnattendSettings.psd1). Open the file in a PowerShell scripting editor and read the comments.
8. Define the **Post installation steps** of the VMs by modifying your copy of [3_PostInstallScripts.psd1](./3_PostInstallScripts.psd1). Open the file in a PowerShell scripting editor and read the comments.