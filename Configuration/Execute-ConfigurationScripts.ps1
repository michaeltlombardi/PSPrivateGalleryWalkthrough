[cmdletbinding()]
param (
    [string]$AdminPass,
    [string]$UserPass,
    [string]$ApiKey = (New-Guid | Select-Object -ExpandProperty Guid),
    [string]$EmailAddress = 'First.Last@Domain.com',
    [string]$PrivateGalleryName = 'PSPrivateGallery'
)

Push-Location $PSScriptRoot
New-Object System.Management.Automation.PSCredential ('GalleryAdmin',(ConvertTo-SecureString $AdminPass -AsPlainText -Force)) | Export-Clixml -Path .\GalleryAdminCredFile.clixml
New-Object System.Management.Automation.PSCredential ('GalleryUser',(ConvertTo-SecureString $UserPass -AsPlainText -Force)) | Export-Clixml -Path .\GalleryUserCredFile.clixml

# Update the environment variables with those specified at build time.
$UpdatedGalleryEnvironment = Get-Content .\PSPrivateGalleryEnvironment.psd1 | ForEach-Object {
    $_.Replace('PSPrivateGallery',$PrivateGalleryName)
}
$UpdatedGalleryEnvironment | Out-File .\PSPrivateGalleryEnvironment.psd1

$UpdatedGalleryPublishEnvironment = Get-Content .\PSPrivateGalleryPublishEnvironment.psd1 | ForEach-Object {
    $Processing = $_.Replace('PSPrivateGallery',$PrivateGalleryName)
    $Processing = $Processing.Replace('First.Last@Domain.com',$EmailAddress)
    $Processing.Replace('ApiKeyGuid',$ApiKey)
}
$UpdatedGalleryPublishEnvironment | Out-File .\PSPrivateGalleryPublishEnvironment.psd1

& .\PSPrivateGallery.ps1
& .\PSprivateGalleryPublish.ps1
Pop-Location