---
Tags: concept
      PowerShell
      DSC
---
# Private Gallery Configurations
For this walkthrough we've largely been leveraging the [PSPrivateGallery Project's](https://github.com/PowerShell/PSPrivateGallery) DSC configuration scripts with some minor edits.

For the rest of this article we're going to break down the configuration pieces resource by resource.
This article assumes you're familiar with [Desired State Configuration]() itself and have some familiarity with the syntax.

## PSPrivateGallery.ps1

### Local Configuration Manager
The first configuration block of `PSPrivateGallery.ps1` deals with the [local coniguration manager]().
It ensures that the node will apply configurations exactly once, reboot if necessary, and continue to apply the configurations after reboot.
```powershell
[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = 'ApplyOnly'
            ActionAfterReboot = 'ContinueConfiguration'
        }
    }
}
```

###PSPrivate Gallery
Installing the PowerShell Gallery requires DSC resources for both the gallery itself and for the IIS web server it will be running inside.

```powershell
Import-DscResource -Module PSGallery
Import-DscResource -Module xWebAdministration
```

The configuration of the Private Gallery is *only* applied to those nodes in `PSPrivateGalleryEnvironment.psd1` which have the role 'WebServer'.

```powershell
Node $AllNodes.Where{$_.Role -eq 'WebServer'}.Nodename
```

