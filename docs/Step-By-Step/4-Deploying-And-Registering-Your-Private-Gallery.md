---
Tags:     tutorial
          step-by-step
          vsts
          build
          deploy
          packagemanagement
Comments: true
---
# Deploying and Registering Your Private Gallery

## Deploying Your Private Gallery
So, assuming everything went well in [Step 3](3-Defining-Your-VSTS-Build.md), you're ready to deploy your private gallery instance to Azure.

You can do that from your build definition - once you've verified the task definitions and variables, save the Build Definition *if you are using a dedicated Build Server*. If you're using the Hosted Build Servers, you'll have to split up your build - unfortunately, the build will bust the 30m agent maximum!

If you're using the hosted build agent, disable the last step (the PowerShell on a Remote Machine step, which executes the configuration).

Then click the 'Queue Build' button and VSTS will start looking for a hosted build agent to use for your build!

Be prepared - the deployment itself can take a long time - in my tests, close to 30 minutes - to complete.

If you're using the Hosted Build Agent, after the build completes you'll want to edit your build definition - disable the file copies (since the files have already been copied over) and enable the PowerShell step.
Then run the build a second time.

**Note:** Even though you run the build a second time, the ARM Template deployment is idempotent - because no changes were made to the template, the first build step will just guarantee that the resources are in the expected state.
Then it will move on to applying the configuration.
This may also take close to thirty minuts.

You've probably noticed that this build (or builds, if you've had to split it in half due to the free hosted agent limitations) takes a while.
However, in that block of time the build is:

1. Deploying a Virtual Machine, configuring a virtual network, registering a DNS entry, setting up firewall rules, and configuring storage.
2. Copying modules, installers, and configuration documents to the new VM.
3. Configuring the VM - including installing and configuring both IIS and SQLExpress, configuring and standing up a website, and downloading and registering packages for the repository.

## Interlude: On Infrastucture as Code
While you're waiting for the deployment to finish, here's a few questions for you:

+ How long would it take you to do those tasks by hand?
+ How confident could you be that the process was exactly what you were expecting?
+ How easily could you make a change to one step of the process and be assured that your node can be successfully redeployed?
+ What conversations might you have with your team or organization about the settings and configuration of the gallery?
+ How can you be assured that those settings and configurations are implemented? Documented?
+ How repeatable would a manual version of this process be?
+ How quickly could you test and modify a manual process for use in another domain or environment?

There are no trick questions here, no clever answers.
The 'simple' truth is this: infrastructure as code is a way to make our deployments safer, more consistent, easier to modify, and easier for people in our team and across other teams to review, improve, and learn about the systems being deployed.
There's no magic involved.

Hopefully, your build should be just about finished now!

## Registering Your Private Gallery
Assuming your build didn't error out, you should now have a working Private Gallery!
Want to prove it?
Open a PowerShell prompt on your local machine.

```powershell
Register-PSRepository -Name '<galleryName>' -SourceLocation 'http://<vmName>.<location>.cloudapp.azure.com/api/v2' -InstallationPolicy Trusted
```

Make sure to replace `<galleryName>` and `<vmName>` with whatever you used for that variable in your build definition (without the angle brackets) and `<location>` with whichever Azure region you deployed your private gallery to.
For example, if I deployed a private gallery called `stlpsug` on a VM called `pspg01` in the `East US` region:
```powershell
Register-PSRepository -Name stlpsug -SourceLocation http://pspg01.eastus.cloudapp.azure.com/api/v2 -InstallationPolicy Trusted
```

Then, search to see what packages are available on the remote repository (replace stlpsug with the name of your own private gallery):
```powershell
Find-Package -Repostory stlpsug
```

You should get back output like this:
```
Version    Name                                Type       Repository           Description
-------    ----                                ----       ----------           -----------
0.6.1.2... posh-git                            Module     stlpsug              A PowerShell environment for Git
3.4.0      Pester                              Module     stlpsug              Pester provides a framework for runni...
1.6.0      PSScriptAnalyzer                    Module     stlpsug              PSScriptAnalyzer provides script anal...
0.1.15     PSDeploy                            Module     stlpsug              Module to simplify PowerShell based d...
4.6.0      psake                               Module     stlpsug              psake is a build automation tool writ...
0.6.1      platyPS                             Module     stlpsug              Generate PowerShell External Help fil...
1.2        PSReadline                          Module     stlpsug              Great command line editing in the Pow...
```

That's it!
We've deployed *and* registered our very own private PowerShell repository!