---
Tags:     concept
          PowerShell
          DSC
Comments: true
---
# Private Gallery Configurations
For this walkthrough we've largely been leveraging the [PSPrivateGallery Project's](https://github.com/PowerShell/PSPrivateGallery) DSC configuration scripts with some minor edits.

For the rest of this article we're going to break down the configuration pieces resource by resource.
This article assumes you're familiar with [Desired State Configuration]() itself and have some familiarity with the syntax.

But before we dive into the configurations we need to talk about the script that calls them.

## Execute-ConfigurationScripts.ps1
The execution script, `Execute-ConfigurationScripts.ps1`, is what the VSTS build uses to modify and run the DSC Configurations below.

### Parameters
It has several parameters:

+ **AdminPass:** The password that will be used for the PowerShell Private Gallery's admin account (named 'GalleryAdmin' by default).
+ **UserPass:** The password that will be used for a user account for the PowerShell Private Gallery (named 'GalleryUser' by default).
+ **ApiKey:** An API key is guid used when you want to publish modules to the PowerShell Private Gallery - if you don't specify one, a random guid will be assigned.
+ **EmailAddress:** The email address for the admin account.
+ **PrivateGalleryName:** The name of the PowerShell Private gallery - this is the name you'll use when registering the private repository.

### Generate User and Admin Credentials
First, the execution script moves it's current location to the Configuration folder - this is to reduce the length of the paths in the code below.
Then the execution script creates a PowerShell credential and exports it as XML.
This allows the configurations to use the credentials when setting up the user accounts.

This step *must* be completed on the box by the VM admin account - these credentials can *only* be read by the same account that creates them.

```powershell
Push-Location $PSScriptRoot
New-Object System.Management.Automation.PSCredential ('GalleryAdmin',(ConvertTo-SecureString $AdminPass -AsPlainText -Force)) | Export-Clixml -Path .\GalleryAdminCredFile.clixml
New-Object System.Management.Automation.PSCredential ('GalleryUser',(ConvertTo-SecureString $UserPass -AsPlainText -Force)) | Export-Clixml -Path .\GalleryUserCredFile.clixml
```

### Modify Configuration Data Files
The next prerequisite to applying the configurations is to overwrite the values in the data files with the variables we pulled in as parameters.
For the first data file (used in `PSPrivateGallery.ps1`) we just replace the default Private Gallery name ('PSPrivateGallery') with the value of the `PrivateGalleryName` parameter.

```powershell
$UpdatedGalleryEnvironment = Get-Content .\PSPrivateGalleryEnvironment.psd1 | ForEach-Object {
    $_.Replace('PSPrivateGallery',$PrivateGalleryName)
}
$UpdatedGalleryEnvironment | Out-File .\PSPrivateGalleryEnvironment.psd1
```

For the second data file, `PSPrivateGalleryPublishEnvironment.psd1`, we replace the default Private Gallery name *as well as* the default emailaddress and placeholder text for the API key.

```powershell
$UpdatedGalleryPublishEnvironment = Get-Content .\PSPrivateGalleryPublishEnvironment.psd1 | ForEach-Object {
    $Processing = $_.Replace('PSPrivateGallery',$PrivateGalleryName)
    $Processing = $Processing.Replace('First.Last@Domain.com',$EmailAddress)
    $Processing.Replace('ApiKeyGuid',$ApiKey)
}
$UpdatedGalleryPublishEnvironment | Out-File .\PSPrivateGalleryPublishEnvironment.psd1
```

### Execute the Configurations
Finally, we execute both of the configurations.
First we execute `PSPrivateGallery.ps1` - this installs the software and manages the prerequisites for setting up the private gallery.
Then we execute `PSPrivateGalleryPublish.ps1` - this manages the configuration of the gallery and ensures the actual service.
Finally, we return the prompt to it's original path via `Pop-Location`.

```powershell
& .\PSPrivateGallery.ps1
& .\PSprivateGalleryPublish.ps1
Pop-Location
```

## PSPrivateGalleryEnvironment.psd1
This is the data file that `PSPrivateGallery.ps1` will read for the configuration of the nodes, so it's important that we discuss it here before we move onto the configuration.

The environment data file is structured such that you can add additional nodes if you want to - it's setup up to be able to handle multiple nodes though only one is specified.

We set the name of the node to localhost because the configuration is running locally.
If we were running these configurations from Azure Automation, we would specify the computername of the VM instead.

We set the role to web server (because the private gallery is one!) and we allow DSC to store the passwords of the gallery admin and user accounts in plaintext.

This is *not* best practice and we're going to modify this project to fix this - see issue [#11](https://github.com/michaeltlombardi/PSPrivateGalleryWalkthrough/issues/11).

```powershell
NodeName                    = 'localhost'
Role                        = 'WebServer'
PsDscAllowPlainTextPassword = $true
```

The next section of the data files is to set the installer paths for the URL rewriter package and SQL Server Express.
These software packages are required for the private gallery.

```powershell
UrlRewritePackagePath       = 'C:\PSPG\Installers\rewrite_amd64.msi'
SqlExpressPackagePath       = 'C:\PSPG\Installers\SqlLocalDB_x64.msi'
```

Then we specify the paths to the private gallery admin credential file and the path to where the packages will be stored for the private gallery.

```powershell
GalleryAdminCredFile        = 'C:\PSPG\Configuration\GalleryAdminCredFile.clixml'
GallerySourcePath           = 'C:\Program Files\WindowsPowerShell\Modules\PSGallery\GalleryContent\'
```

The next part of the environment datafile holds the configuration variables for the private gallery website.
This configuration configures the gallery to be the default website of the server and sets the website's folder path to the name of your private gallery (remember, the execution script overwrites all instances of 'PSPrivateGallery' in this file with the name you specified for the private gallery). For example, if you specified the name of the private gallery to be 'stlpsug', the website path would be set to `C:\stlpsug`.

It also sets the application pool to the default, and sets the port to 80 for standard HTTP.

```powershell
WebsiteName                 = 'Default Web Site'
WebsitePath                 = 'C:\PSPrivateGallery'
AppPoolName                 = 'DefaultAppPool'
WebsitePort                 = 80
```

Finally, the data file contains the configuration information for SQL.
We set both the instance and database names to the name of private gallery.

**Reminder:** All instances of 'PSPrivateGallery' in this file are rewritten by the execution script to whatever you named the private gallery!

 ```
SqlInstanceName             = 'PSPrivateGallery'
SqlDatabaseName             = 'PSPrivateGallery'
 ```

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

In the [Execution Script](#execute-configurationscriptsps1) we set the admin credentials - now we're going to read those in from the local disk and use those credentials for setting up the requisite software and services.

```powershell
# Obtain credential for Gallery setup operations
$GalleryCredential = (Import-Clixml $Node.GalleryAdminCredFile)
```

Next up we're going to configure the web server for the PowerShell private gallery.
Notice that almost *all* of the information here was set in the `PSPrivateGalleryEnvironment.psd1` - the path to where the URL rewrite package is located, the admin credential for the app pool, the path to where the PowerShell packages will be stored, the name of the website and the path to it, the port the website will be set on, and the name of the app pool.

```powershell
PSGalleryWebServer GalleryWebServer
{
      UrlRewritePackagePath = $Node.UrlRewritePackagePath
      AppPoolCredential     = $GalleryCredential
      GallerySourcePath     = $Node.GallerySourcePath
      WebSiteName           = $Node.WebsiteName
      WebsitePath           = $Node.WebsitePath
      WebsitePort           = $Node.WebsitePort
      AppPoolName           = $Node.AppPoolName
}
```

The database for the gallery also gets its settings defined back in the environment datafile - the path to the installer, the credential for SQL (notice it's the same as the overall PSGallery admin), and the name of the instance and database - in both cases, this is the same name as the private gallery.

```powershell
PSGalleryDataBase GalleryDataBase
{
      SqlExpressPackagePath    = $Node.SqlExpressPackagePath
      DatabaseAdminCredential  = $GalleryCredential
      SqlInstanceName          = $Node.SqlInstanceName
      SqlDatabaseName          = $Node.SqlDatabaseName
}
```

In an unsurprising turn of events, the database migration resource *also* gets its settings from the datafile - the private gallery name for the instance and database, the admin credential, and a setting that ensures this runs after the GalleryDataBase resource above. 

```powershell
# Migrate entity framework schema to SQL DataBase
# This is agnostic to the type of SQL install - SQL Express/Full SQL
# Hence a separate resource
PSGalleryDatabaseMigration GalleryDataBaseMigration
{
      DatabaseInstanceName = $Node.SqlInstanceName
      DatabaseName         = $Node.SqlDatabaseName
      PsDscRunAsCredential = $GalleryCredential
      DependsOn            = '[PSGalleryDataBase]GalleryDataBase'
}
```

Finally, the configuration requires a connection string to be setup.
We ensure that the connection string exists, name it, attach it to the gallery website, and generate the connection string.
Lastly, the connection string depends on both the migration and web server resources.

```powershell
xWebConnectionString SQLConnection
{
      Ensure           = 'Present'
      Name             = 'Gallery.SqlServer'
      WebSite          = $Node.WebsiteName
      ConnectionString = "Server=(LocalDB)\$($Node.SqlInstanceName);Initial Catalog=$($Node.SqlDatabaseName);Integrated Security=True"
      DependsOn        = '[PSGalleryWebServer]GalleryWebServer','[PSGalleryDataBaseMigration]GalleryDataBaseMigration'
}
```

### Executing the Configurations
First, the script builds the configuration for the LCM and then executes it.

```powershell
LCMConfig
Set-DscLocalConfigurationManager -Path .\LCMConfig -Force -Verbose -ComputerName localhost
```

Then it will build the configuration for the private gallery and execute it.

```powershell
PSPrivateGallery -ConfigurationData .\PSPrivateGalleryEnvironment.psd1
Start-DscConfiguration -Path .\PSPrivateGallery -Wait -Force -Verbose
```

## PSPrivateGalleryPublishEnvironment.psd1
Again, we need to explore the environment datafile before the configuration script itself will make sense.
This data file also describes a single node.

Again, the nodename is set to localhost.
This time, however, the role is set to Gallery and we again specify that plaintext passwords should be allowed.

```powershell
NodeName                    = 'localhost'
Role                        = 'Gallery'
PsDscAllowPlainTextPassword = $true
```

Again, we set the paths for the credential files.

```powershell
GalleryAdminCredFile        = 'C:\PSPG\Configuration\GalleryAdminCredFile.clixml'
GalleryUserCredFile         = 'C:\PSPG\Configuration\GalleryUserCredFile.clixml'
```

We set the SQL instance and database names again - and, again, they're going to be equal to the name of the private gallery.

```powershell
SQLInstance                 = '(LocalDb)\PSPrivateGallery'
DatabaseName                = 'PSPrivateGallery'
```

This time we also set the email address for the admin account and specify the API key that will be used to publish modules to the gallery.

```powershell
EmailAddress                = 'First.Last@Domain.com'
ApiKey                      = 'Guid'
```

We also set the name and location of the private gallery - PSPrivateGallery will be replaced with the name you specified in `Execute-ConfigurationScripts.ps1`.
The website will run on the localhost on port 80.

```powershell
PrivateGalleryName          = 'PSPrivateGallery'
PrivateGalleryLocation      = 'http://localhost:80'
```

Then we set the information for our source gallery - in this case, we're leveraging the public gallery for our source gallery.

```powershell
SourceGalleryName          = 'PSGallery'
SourceGalleryLocation      = 'https://www.powershellgallery.com'
```

Finally, we specify what modules should be published to the private gallery from the source gallery.
In our case, we're only specifying a minimum version because we always want the gallery to pull down the latest one.

```powershell
Modules = @(
                @{
                    ModuleName     = 'Pester'
                    MinimumVersion = '3.4'
                }
                @{
                    ModuleName     = 'PSDeploy'
                    MinimumVersion = '0.1.8'
                }
                @{
                    ModuleName     = 'PSScriptAnalyzer'
                    MinimumVersion = '1.6'
                }
                @{
                    ModuleName     = 'posh-git'
                    MinimumVersion = '0.6'
                }
                @{
                    ModuleName     = 'psake'
                    MinimumVersion = '4.6'
                }
                @{
                    ModuleName     = 'platyPS'
                    MinimumVersion = '0.5'
                }
                @{
                    ModuleName = 'PSReadline'
                    MinimumVersion = '1.2'
                }
            )
}
```

## PSPrivateGalleryPublish.ps1
This script manages the configuration of the gallery itself now that the prerequisites components are in place.

### PSPrivateGalleryPublish
Before we configure the private gallery node(s) we import the required DSC resources - PSGallery and the resource for Package Management providers.

```powershell
Import-DscResource -ModuleName PSGallery
Import-DscResource -ModuleName PackageManagementProviderResource
```

Then we retrieve the stored credentials again.

```powershell
$GalleryAppPoolCredential = (Import-Clixml $Node.GalleryAdminCredFile)
$GalleryUserCredential    = (Import-Clixml $Node.GalleryUserCredFile)
```

We then define the source gallery for our private gallery - the name, provider, where it's located, the credential to add it under (the admin credential), that it should be installed and trusted.

```powershell
PackageManagementSource SourceGallery
{
    Name                 = $Node.SourceGalleryName
    ProviderName         = 'PowerShellGet'
    SourceUri            = $Node.SourceGalleryLocation
    PsDscRunAsCredential = $GalleryAppPoolCredential
    Ensure               = 'Present'
    InstallationPolicy   = 'Trusted'
}
```

We then do the same thing for the private gallery itself:

```powershell
PackageManagementSource PrivateGallery
{
    Name                 = $Node.PrivateGalleryName
    ProviderName         = 'PowerShellGet'
    SourceUri            = $Node.PrivateGalleryLocation
    PsDscRunAsCredential = $GalleryAppPoolCredential
    Ensure               = 'Present'
    InstallationPolicy   = 'Trusted'
}
```

The Gallery user needs to be configured as well - note that if you want to specify multiple users, that can be done too.
Setting the user requires specifying the database in which the user will be stored, that the user should exist, the credential of the user, the credential of the account that can add the user, the user's email address, and the user's API key.

```powershell
PSGalleryUser PrivateGalleryUser
{
    DatabaseInstance      = $Node.SQLInstance
    DatabaseName          = $Node.DatabaseName
    Ensure                =  'Present'
    UserCredential        = $GalleryUserCredential
    PsDscRunAsCredential  = $GalleryAppPoolCredential
    EmailAddress          = $Node.EmailAddress
    ApiKey                = $Node.ApiKey
}
```

Finally for the configuration we need to deal with the modules.
First we make sure that the modules are installed and configured, specifying both the source and private gallery names, the credential of the account which will publish these initial modules, and the API key for publishing the modules.

The next portion is more complicated - it reads the Modules section of the environmental data file above (which was an array of hash tables) and adds a configuration item for each module listed.
Every module specification requires the modules name and one of the following: RequiredVersion, MinimumVersion, and MaximumVersion.
These modules will be loaded into the private gallery.

Finally, this resource depends on the source gallery, private gallery, and user being set up.

```powershell
PSGalleryModule PrivateGalleryModule
{
    Ensure                      = 'Present'

    SourceGalleryName           = $Node.SourceGalleryName
    PrivateGalleryName          = $Node.PrivateGalleryName

    PsDscRunAsCredential        = $GalleryAppPoolCredential

    ApiKey                      = $Node.ApiKey

    Modules                     = $Node.Modules | % {
                                                ModuleSpecification
                                                {
                                                    Name = $_.ModuleName
                                                    RequiredVersion = $_.RequiredVersion
                                                    MinimumVersion = $_.MinimumVersion
                                                    MaximumVersion = $_.MaximumVersion
                                                }
                                    }

    DependsOn                   = '[PackageManagementSource]SourceGallery','[PackageManagementSource]PrivateGallery','[PSGalleryUser]PrivateGalleryUser'
}
```

### Executing the Configuration
And, very finally, we execute the configuration.
This will read in the datafile and build the configuration from the code above and then run it.

```powershell
PSPrivateGalleryPublish -ConfigurationData .\PSPrivateGalleryPublishEnvironment.psd1
Start-DscConfiguration -Path .\PSPrivateGalleryPublish -Wait -Force -Verbose
```

## Conclusion
This page was long and complex but we've now covered the execution script, the environmental datafiles, and the configurations themselves.

If you have any questions, comments or concerns - if you find a mistake in this document or if something is not clear to you, *please* file an [issue](https://github.com/michaeltlombardi/PSPrivateGalleryWalkthrough/issues/new) and it will be addressed.