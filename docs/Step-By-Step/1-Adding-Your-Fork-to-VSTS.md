---
Tags: tutorial
      step-by-step
      vsts
      github
---
# Adding Your Fork to VSTS
First, navigate to your VSTS project - it should be something like `https://youraccountname.visualstudio.com/PSPrivateGallery` if you set it up during the *Getting Started* tutorial.
Once you're there, click the small cog in the top righthand corner.

![The cog is in the top right on the menu bar](../Static/1-settings-cog.PNG "Settings Cog")

This will open a new tab and bring you to the control panel for the project.
Select the 'Services' tab, then click on the 'New Service Endpoint' option on the top left and choose 'Github' from the drop down menu.

![Selecting the Github Service Endpoint in VSTS](../Static/1-github-service-endpoint.PNG "Selecting the Github Service Endpoint Option")

On the pop up, click the 'Authorize' button and follow the directions to authenticate, if any.
After authentication, the connection name should automatically populate and you should see a message and green check mark indicated you're authenticated.
Click OK.

![Authenticated Github Service Endpoint in VSTS](../Static/1-github-service-authenticated.PNG)

Switch tabs back to the your project page and click the menu option for 'BUILD'.

![Selecting the Build tab](../Static/1-select-build.PNG "Build Option")

Once on the build page, click the green plus sign on the top left; this will prompt you to create a new build definition.
Select the 'Empty' option at the bottom of the prompt, then click 'Next'.

![Creating a new build definition](../Static/1-choose-empty.PNG "Make sure to select the empty build definition")

On the setting page, choose Github and make sure the Default agent queue is set to 'Hosted'. Then click 'Create'.

![Adding Github to the build definition](../Static/1-add-github-to-build.PNG)

Select the Repository tab under the Build definition.
You should see that it has autofilled the connection, repository, and default branch.
Change the repository setting to `<yourusername>/PSPrivateGalleryWalkthrough`.

Click the save button.

That's it!
Next, we're going to look at adding an Azure endpoint.