---
Tags:     tutorial
          step-by-step
          packagemanagement
          post-deploy
Comments: true
---
# Publishing To Your Private Gallery
The final step in using your private gallery is to be able to publish your own modules to your private gallery.

## Publishing Your First Package
The easiest way to publish to your private gallery is to navigate to the folder in which the module you want to publish is located.
For the purposes of this Walkthrough, you can navigate to the `ExampleModules` folder.

You're going to need the guid you used for the `galleryApiKey` in the build definition. 
In the below example, `f3b0edb5-99da-4bef-a66f-4bbd372a45e5` was the API key used in the build and `stlpsug` was what was used for the `galleryName` variable.

```powershell
Publish-Module -Path ExampleModules\0.1.0 -Repository stlpsug -NugetApiKey 'f3b0edb5-99da-4bef-a66f-4bbd372a45e5'
```

**Note:** Install NuGet if prompted.

If that worked, we're also going to publish a few more versions of the module:
```powershell
Publish-Module -Path ExampleModule\0.2.0 -Repository stlpsug -NugetApiKey 'f3b0edb5-99da-4bef-a66f-4bbd372a45e5'
Publish-Module -Path ExampleModule\0.1.1 -Repository stlpsug -NugetApiKey 'f3b0edb5-99da-4bef-a66f-4bbd372a45e5'
Publish-Module -Path ExampleModule\1.0.0 -Repository stlpsug -NugetApiKey 'f3b0edb5-99da-4bef-a66f-4bbd372a45e5'
```

You **should** get an error when trying to publish ExampleModule v0.1.1 - the publishing mechanism does not allow you to publish a version of a module older than those already published to the gallery.
You will have to always register your packages in order from lowest version to highest if you want to include older versions of the module.

To see that the packages were in fact published:

```powershell
Find-Module -Name ExampleModule -Repository stlpsug -AllVersions
```

```
Version    Name                                Type       Repository           Description
-------    ----                                ----       ----------           -----------
1.0.0      ExampleModule                       Module     stlpsug              Example Module for PSPrivateGalleryWalkthrough
0.2.0      ExampleModule                       Module     stlpsug              Example Module for PSPrivateGalleryWalkthrough
0.1.0      ExampleModule                       Module     stlpsug              Example Module for PSPrivateGalleryWalkthrough
```

And there you have it - you've successfully published modules to your private gallery!
From here on out, you can find and install modules from your private gallery the same way you would from the public PSGallery.

Congratulations!