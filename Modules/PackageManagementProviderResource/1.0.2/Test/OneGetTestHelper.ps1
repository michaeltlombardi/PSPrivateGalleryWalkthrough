#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

<# Run Test cases Pre-Requisite: 
  1. After download the OngetGet DSC resources modules, it is expected the following are available under your current directory. For example,

    C:\Program Files\WindowsPowerShell\Modules\PackageManagementProviderResource\
        
        DSCResources
        Examples
        Test
        PackageManagementProviderResource.psd1
#>

#Define the variables

$CurrentDirectory            = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

$script:LocalRepositoryPath  = "$CurrentDirectory\LocalRepository"
$script:LocalRepositoryPath1 = "$CurrentDirectory\LocalRepository1"
$script:LocalRepositoryPath2 = "$CurrentDirectory\LocalRepository2"
$script:LocalRepositoryPath3 = "$CurrentDirectory\LocalRepository3"
$script:LocalRepository      = "LocalRepository"
$script:InstallationFolder   = $null
$script:DestinationPath      = $null
$script:Module               = $null



#A DSC configuration for installing Pester
configuration Sample_InstallPester
{
    <#
    .SYNOPSIS

    This is a DSC configution that install/uninstall the Pester tool from the nuget. 

    .PARAMETER DestinationPath
    Provides the file folder where the Pester to be installed.

    #>

    param
    (
        #Destination path for the package
        [Parameter(Mandatory)]
        [string]$DestinationPath       
    )

    Import-DscResource -Module PackageManagementProviderResource

    Node "localhost"
    {
        
        #register package source       
        PackageManagementSource SourceRepository
        {

            Ensure      = "Present"
            Name        = "Mynuget"
            ProviderName= "Nuget" 
            SourceUri   = "http://nuget.org/api/v2/"    
            InstallationPolicy ="Trusted"
        }   
        
        #Install a package from Nuget repository
        NugetPackage Nuget
        {
            Ensure          = "Present"
            Name            = "Pester"
            DestinationPath = $DestinationPath
            DependsOn       = "[PackageManagementSource]SourceRepository"
            InstallationPolicy="Trusted"
        }                              
    } 
}

Function InstallPester
{
    <#
    .SYNOPSIS

    This function downloads and installs the pester tool. 

    #>

    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    # Check if the Pester have installed already under Program Files\WindowsPowerShell\Modules\Pester
    $pester = Get-Module -Name "Pester" -ListAvailable

    if ($pester.count -ge 1)
    {
        Write-Verbose -Message "Pester has already installed under $($pester.ModuleBase)" 

        Import-module -Name "$($pester.ModuleBase)\Pester.psd1"          
    }
    else
    {
        # Get the module path where to be installed
        $module = Get-Module -Name "PackageManagementProviderResource" -ListAvailable

        # Compile it
        Sample_InstallPester -DestinationPath "$($module.ModuleBase)\test"

        # Run it
        Start-DscConfiguration -path .\Sample_InstallPester -wait -Verbose -force 

        $result = Get-DscConfiguration 
    
        #import the Pester tool. Note:$result.Name is something like 'Pester.3.3.5'
        Import-module -Name "$($module.ModuleBase)\test\$($result[1].Name)\tools\Pester.psd1"
    }
 }


Function SetupLocalRepository
{
    <#
    .SYNOPSIS

    This is a helper function to setup a local repostiory/package resouce to speed up the test execution

    .PARAMETER PSModule
    Provides whether you are testing PowerShell Modules or Packages.

    #>

    param
	(
        [Switch]$PSModule
    )

    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")
    
    # Create the LocalRepository path if does not exist
    if (-not ( Test-Path -Path $script:LocalRepositoryPath))
    {
        New-Item -Path $script:LocalRepositoryPath -ItemType Directory -Force  
        New-Item -Path $script:LocalRepositoryPath1 -ItemType Directory -Force  
        New-Item -Path $script:LocalRepositoryPath2 -ItemType Directory -Force  
        New-Item -Path $script:LocalRepositoryPath3 -ItemType Directory -Force  
    }

    # UnRegister repository/sources
    UnRegisterAllSource

    # Register the local repository
    RegisterRepository -Name $script:LocalRepository -InstallationPolicy Trusted -Ensure Present

    # Create test modules for the test automation
    if ($PSModule)
    {
        # Set up for PSModule testing
        CreateTestModuleInLocalRepository -ModuleName "MyTestModule"  -ModuleVersion "1.1"    -LocalRepository $script:LocalRepository
        CreateTestModuleInLocalRepository -ModuleName "MyTestModule"  -ModuleVersion "1.1.2"  -LocalRepository $script:LocalRepository
        CreateTestModuleInLocalRepository -ModuleName "MyTestModule"  -ModuleVersion "3.2.1"  -LocalRepository $script:LocalRepository
    }
    else
    {
        #Setup for nuget and others testing
        CreateTestModuleInLocalRepository -ModuleName "MyTestPackage" -ModuleVersion "12.0.1"   -LocalRepository $script:LocalRepository
        CreateTestModuleInLocalRepository -ModuleName "MyTestPackage" -ModuleVersion "12.0.1.1" -LocalRepository $script:LocalRepository
        CreateTestModuleInLocalRepository -ModuleName "MyTestPackage" -ModuleVersion "15.2.1"   -LocalRepository $script:LocalRepository
    }

    # Replica the repository    
    Copy-Item -Path "$script:LocalRepositoryPath\*" -Destination $script:LocalRepositoryPath1 -Recurse -force 
    Copy-Item -Path "$script:LocalRepositoryPath\*" -Destination $script:LocalRepositoryPath2 -Recurse -force     
    Copy-Item -Path "$script:LocalRepositoryPath\*" -Destination $script:LocalRepositoryPath3 -Recurse -force
}

Function SetupPSModuleTest
{
    <#
    .SYNOPSIS

    This is a helper function for a PSModule test

    #>

    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    #Need to import resource MSFT_PSModule.psm1
    Import-ModulesToSetupTest -ModuleChildPath  "MSFT_PSModule\MSFT_PSModule.psm1"  

    SetupLocalRepository -PSModule 

    # Install Pester and import it
    InstallPester      
}

Function SetupNugetTest
{
    <#
    .SYNOPSIS

    This is a helper function for a Nuget test

    #>
    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    #Import MSFT_NugetPackage.psm1 module
    Import-ModulesToSetupTest -ModuleChildPath  "MSFT_NugetPackage\MSFT_NugetPackage.psm1"
    
    $script:DestinationPath = "$CurrentDirectory\TestResult\NugetTest" 

    SetupLocalRepository

    # Install Pester and import it
    InstallPester
 }

Function SetupOneGetSourceTest
{
    <#
    .SYNOPSIS

    This is a helper function for a PackageManagementSource test

    #>
    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    Import-ModulesToSetupTest -ModuleChildPath  "MSFT_PackageManagementSource\MSFT_PackageManagementSource.psm1"

    SetupLocalRepository

    # Install Pester and import it
    InstallPester 
}

Function Import-ModulesToSetupTest
{
    <#
    .SYNOPSIS

    This is a helper function to import modules
    
    .PARAMETER ModuleChildPath
    Provides the child path of the module. The parent path should be the same as the DSC resource.
    #>

    param
    (
    	[parameter(Mandatory = $true)]
		[System.String]
		$ModuleChildPath

    )
  
    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    $moduleChildPath="DSCResources\$($ModuleChildPath)"

    $script:Module = Get-Module -Name "PackageManagementProviderResource" -ListAvailable

    $modulePath = Microsoft.PowerShell.Management\Join-Path -Path $script:Module.ModuleBase -ChildPath $moduleChildPath

    Import-Module -Name "$($modulePath)"  
    
    #c:\Program Files\WindowsPowerShell\Modules
    $script:InstallationFolder = "$($script:Module.ModuleBase)" 
 }

function RegisterRepository
{
    <#
    .SYNOPSIS

    This is a helper function to register/unregister the PowerShell repository

    .PARAMETER Name
    Provides the repository Name.

    .PARAMETER SourceLocation
    Provides the source location.

    .PARAMETER PublishLocation
    Provides the publish location.

    .PARAMETER InstallationPolicy
    Determines whether you trust the source repository.

    .PARAMETER Ensure
    Determines whether the repository to be registered or unregistered.
    #>

    param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.String]
		$SourceLocation=$script:LocalRepositoryPath,
   
   		[System.String]
		$PublishLocation=$script:LocalRepositoryPath,

        [ValidateSet("Trusted","Untrusted")]
		[System.String]
		$InstallationPolicy="Trusted",

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure="Present"
	)

    Write-Verbose -Message "RegisterRepository called" 

    # Calling the following to trigger Bootstrap provider for the first time use PackageManagement
    Get-PackageSource -ProviderName Nuget -ForceBootstrap -WarningAction Ignore 

    $psrepositories = PowerShellGet\get-PSRepository
    $registeredRepository = $null
    $isRegistered = $false

    #Check if the repository has been registered already
    foreach ($repository in $psrepositories)
    {
        # The PSRepository is considered as "exists" if either the Name or Source Location are in used
        $isRegistered = ($repository.SourceLocation -ieq $SourceLocation) -or ($repository.Name -ieq $Name) 

        if ($isRegistered)
        {
            $registeredRepository = $repository
            break;
        }
    }

    if($Ensure -ieq "Present")
    {       
        # If the repository has already been registered, unregister it.
        if ($isRegistered -and ($null -ne $registeredRepository))
        {
            Unregister-PSRepository -Name $registeredRepository.Name
        }       

        PowerShellGet\Register-PSRepository -Name $Name -SourceLocation $SourceLocation -PublishLocation $PublishLocation -InstallationPolicy $InstallationPolicy
    }
    else
    {
        # The repository has already been registered
        if (-not $isRegistered)
        {
            return
        }

        PowerShellGet\UnRegister-PSRepository -Name $Name
    }            
}

function RestoreRepository
{
    <#
    .SYNOPSIS

    This is a helper function to reset back your test environment.

    .PARAMETER RepositoryInfo
    Provides the hashtable containing the repository information used for regsitering the repositories.
    #>

    param
	(
        [parameter(Mandatory = $true)]
		[Hashtable]
		$RepositoryInfo
	)

    Write-Verbose -Message "RestoreRepository called"  
       
    foreach ($repository in $RepositoryInfo.Keys)
    {
        try
        {
            $null = PowerShellGet\Register-PSRepository -Name $RepositoryInfo[$repository].Name `
                                            -SourceLocation $RepositoryInfo[$repository].SourceLocation `
                                            -PublishLocation $RepositoryInfo[$repository].PublishLocation `
                                            -InstallationPolicy $RepositoryInfo[$repository].InstallationPolicy `
                                            -ErrorAction SilentlyContinue 
        }
        #Ignore if the repository already registered
        catch
        {
            if ($_.FullyQualifiedErrorId -ine "PackageSourceExists")
            {
                throw
            }
        }                                    
    }   
}

function CleanupRepository
{
    <#
    .SYNOPSIS

    This is a helper function for the test setp. Sometimes tests require no other repositories
    are registered, this function helps to do so

    #>

    Write-Verbose -Message "CleanupRepository called" 

    $returnVal = @{}
    $psrepositories = PowerShellGet\get-PSRepository

    foreach ($repository in $psrepositories)
    {
        #Save the info for later restore process
        $repositoryInfo = @{"Name"=$repository.Name; `
                            "SourceLocation"=$repository.SourceLocation; `
                            "PublishLocation"=$repository.PublishLocation;`
                            "InstallationPolicy"=$repository.InstallationPolicy}

        $returnVal.Add($repository.Name, $repositoryInfo);

        try
        {
            $null = Unregister-PSRepository -Name $repository.Name -ErrorAction SilentlyContinue 
        }
        catch
        {
            if ($_.FullyQualifiedErrorId -ine "RepositoryCannotBeUnregistered")
            {
                throw
            }
        }         
    }   
    
    Return $returnVal   
}

function RegisterPackageSource
{
    <#
    .SYNOPSIS

    This is a helper function to register/unregister the package source

    .PARAMETER Name
    Provides the package source Name.

    .PARAMETER SourceUri
    Provides the source location.

    .PARAMETER PublishLocation
    Provides the publish location.

    .PARAMETER Credential
    Provides the access to the package on a remote source.

    .PARAMETER InstallationPolicy
    Determines whether you trust the source repository.

    .PARAMETER ProviderName
    Provides the package provider name.

    .PARAMETER Ensure
    Determines whether the package source to be registered or unregistered.
    #>

    param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

        #Source location. It can be source name or uri
		[System.String]
		$SourceUri,

		[System.Management.Automation.PSCredential]
		$Credential,
    
		[System.String]
        [ValidateSet("Trusted","Untrusted")]
		$InstallationPolicy ="Untrusted",

		[System.String]
		$ProviderName="Nuget",

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure="Present"
	)

    Write-Verbose -Message "Calling RegisterPackageSource"

    #import the OngetSource module
    Import-ModulesToSetupTest -ModuleChildPath  "MSFT_PackageManagementSource\MSFT_PackageManagementSource.psm1"
    
    if($Ensure -ieq "Present")
    {       
        # If the repository has already been registered, unregister it.
        UnRegisterSource -Name $Name -ProviderName $ProviderName -SourceUri $SourceUri       

        MSFT_PackageManagementSource\Set-TargetResource -Name $name `
                                             -providerName $ProviderName `
                                             -SourceUri $SourceUri `
                                             -SourceCredential $Credential `
                                             -InstallationPolicy $InstallationPolicy `
                                             -Verbose `
                                             -Ensure Present
    }
    else
    {
        # The repository has already been registered
        UnRegisterSource -Name $Name -ProviderName $ProviderName -SourceUri $SourceUri
    } 
    
    # remove the OngetSource module, after we complete the register/unregister task
    Remove-Module -Name  "MSFT_PackageManagementSource"  -Force -ErrorAction SilentlyContinue         
}

Function UnRegisterSource
{
    <#
    .SYNOPSIS

    This is a helper function to unregister a particular package source

    .PARAMETER Name
    Provides the package source Name.

    .PARAMETER SourceUri
    Provides the source location.

    .PARAMETER ProviderName
    Provides the package provider name.
    #>

    param
    (
        [parameter(Mandatory = $true)]
		[System.String]
		$Name,

        [System.String]
		$SourceUri,

    	[System.String]
		$ProviderName="Nuget"
    )

    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    $getResult = MSFT_PackageManagementSource\Get-TargetResource -Name $name -providerName $ProviderName -SourceUri $SourceUri -Verbose

    if ($getResult.Ensure -ieq "Present")
    {
        #Unregister it
        MSFT_PackageManagementSource\Set-TargetResource -Name $name -providerName $ProviderName -SourceUri $SourceUri -Verbose -Ensure Absent               
    }
}

Function UnRegisterAllSource
{
    <#
    .SYNOPSIS

    This is a helper function to unregister all the package source on the machine

    #>

    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    $sources = PackageManagement\Get-PackageSource

    foreach ($source in $sources)
    {
        try
        {
            #Unregister whatever can be unregistered
            PackageManagement\Unregister-PackageSource -Name $source.Name -providerName $source.ProviderName -ErrorAction SilentlyContinue  2>&1   
        }
        catch
        {
            if ($_.FullyQualifiedErrorId -ine "RepositoryCannotBeUnregistered")
            {
                throw
            }
        }         
    }
}

function Get-Credential
{
    <#
    .SYNOPSIS

    This is a helper function for the cmdlets testing where requires PSCredential

    #>

    param(
        [System.String]
        $User, 

        [System.String]
        $Password
    )

    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    $secPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($User, $secPassword)
    return $cred
}

function CreateTestModuleInLocalRepository
{
    <#
    .SYNOPSIS

    This is a helper function that generates test packages/modules and publishes them to a local repository.
    Please note that it only generates manifest files just for testing purpose.

    .PARAMETER ModuleName
    Provides the module Name to be generated.

    .PARAMETER ModuleVersion
    Provides the module version to be generated.

    .PARAMETER LocalRepository
    Provides the local repository Name.
    #>

    param(
        [System.String]
        $ModuleName, 

        [System.String]
        $ModuleVersion,

        [System.String]
        $LocalRepository
    )

    Write-Verbose -Message ("Calling function '$($MyInvocation.mycommand)'")

    # Return if the package already exists
    if (Test-path -path "$($script:Module.ModuleBase)\test\$($LocalRepository)\$($ModuleName).$($ModuleVersion).nupkg")
    {
        return
    }

    # Get the parent 'PackageManagementProviderResource' module path
    $parentModulePath = Microsoft.PowerShell.Management\Split-Path -Path $script:Module.ModuleBase -Parent

    $modulePath = Microsoft.PowerShell.Management\Join-Path -Path $parentModulePath -ChildPath "$ModuleName"

    New-Item -Path $modulePath -ItemType Directory -Force

    $modulePSD1Path = "$modulePath\$ModuleName.psd1"

    # Create the module manifest
    Microsoft.PowerShell.Core\New-ModuleManifest -Path $modulePSD1Path -Description "$ModuleName" -ModuleVersion $ModuleVersion

    try
    {
        # Publish the module to your local repository
        PowerShellGet\Publish-Module -Path $modulePath -NuGetApiKey "Local-Repository-NuGet-ApiKey" -Repository $LocalRepository -Verbose -ErrorAction SilentlyContinue         
    }
    catch
    { 
        # Ignore the particular error
        if ($_.FullyQualifiedErrorId -ine "ModuleVersionShouldBeGreaterThanGalleryVersion,Publish-Module")
        {
            throw
        }               
    }

    # Remove the module under modulepath once we published it to the local repository
    Microsoft.PowerShell.Management\Remove-item -Path $modulePath -Recurse -Force -ErrorAction SilentlyContinue
}
