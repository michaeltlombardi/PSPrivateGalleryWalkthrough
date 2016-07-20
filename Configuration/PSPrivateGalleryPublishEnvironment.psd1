@{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            Role                        = 'Gallery'
            PsDscAllowPlainTextPassword = $true

            GalleryAdminCredFile        = 'C:\PSPG\Configuration\GalleryAdminCredFile.clixml'
            GalleryUserCredFile         = 'C:\PSPG\Configuration\GalleryUserCredFile.clixml'

            SQLInstance                 = '(LocalDb)\PSPrivateGallery'
            DatabaseName                = 'PSPrivateGallery'

            EmailAddress                = 'First.Last@Domain.com'
            ApiKey                      = 'Guid'

            PrivateGalleryName          = 'PSPrivateGallery'
            PrivateGalleryLocation      = 'http://localhost:80'

            SourceGalleryName          = 'PSGallery'
            SourceGalleryLocation      = 'https://www.powershellgallery.com'

            Modules                     = @(
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
    )
}