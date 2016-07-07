[cmdletbinding()]
param (
    [string]$AdminPass,
    [string]$UserPass
)

Push-Location $PSScriptRoot
New-Object System.Management.Automation.PSCredential ('GalleryAdmin',(ConvertTo-SecureString $AdminPass -AsPlainText -Force)) | Export-Clixml -Path .\GalleryAdminCredFile.clixml
New-Object System.Management.Automation.PSCredential ('GalleryUser',(ConvertTo-SecureString $UserPass -AsPlainText -Force)) | Export-Clixml -Path .\GalleryUserCredFile.clixml

& .\PSPrivateGallery.ps1
& .\PSprivateGalleryPublish.ps1
Pop-Location