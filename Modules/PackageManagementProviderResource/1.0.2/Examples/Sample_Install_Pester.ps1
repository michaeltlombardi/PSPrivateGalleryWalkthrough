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
# DSC configuration for NuGet

configuration Sample_InstallPester
{
    param
    (
        #Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost',

        #Name of the package to be installed
        [Parameter(Mandatory)]
        [string]$Name,

        #Destination path for the package
        [Parameter(Mandatory)]
        [string]$DestinationPath,
        
        #Version of the package to be installed
        [string]$RequiredVersion,

        #Source location where the package download from
        [string]$Source,

        #Whether the source is Trusted or Untrusted
        [string]$InstallationPolicy
    )

    Import-DscResource -Module PackageManagementProviderResource

    Node $NodeName
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
            Ensure          = "present" 
            Name            = $Name
            DestinationPath = $DestinationPath
            DependsOn       = "[PackageManagementSource]SourceRepository"
            InstallationPolicy="Trusted"
        }                              
    } 
}


#Compile it
Sample_InstallPester -Name "Pester" -DestinationPath "$env:HomeDrive\test\test" 

#Run it
Start-DscConfiguration -path .\Sample_InstallPester -wait -Verbose -force 
