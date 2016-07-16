---
Tags: tutorial
      step-by-step
      vsts
      github
      build
      azurerm
---
# Creating your Build Defintion
Now we're finally to the interesting part - defining our build.
We're going to set the build up to create the resource group, which will deploy the VM, the network security rules, the network, storage, and DNS entries, as well as apply the Desired State Configurations to the new VM.

## Add the Build Variables
Before we add the build tasks, we need to define some useful variables.

1. Select the 'Variables' tab of the build definition.
2. Select 'Add Variable' and add the following value under the 'Name' column: `resourceGroupName`
3. Select the 'Allow at Queue Time' checkbox.

You're going to add several more variables here, per the table below:

| Name              | Secret | Allow at Queue Time |
|:------------------|:------:|:-------------------:|
| resourceGroupName | false  | true                |
| vmName            | false  | true                |
| vmAdminAccount    | false  | true                |
| vmAdminPassword   | true   | true                |

You can place any string you like in for the value of `resourcegroupName`, `vmName`, and `vmAdminAccount`; these will, unsurprisingly, define the name of the Azure resource group to be created (and in which the gallery will reside), the name of the virtual machine the gallery will be installed on, and the name of the admin account created on the VM.

Notice that the vmAdminPassword is marked as `Secret` - that allows you to safely and securely save the VM Admin's password in the build definition.
You'll be able to unhide it until you save the build definition - at which point you won't be able to retrieve the secret outside of a build.

For all of these values we've elected to make them available for overriding at queue time.
That means we're going to be able to specify any/all of them whenever we run a build.

## Add the Resource Group Deployment Task
In your build definition, select the 'Add a Build Step' button.

This will bring up a menu - select the the 'Deploy' tab, and then the 'Azure Resource Group Deployment' option on that tab.

Click the 'Close' button to return to the build.

![Adding the Resource Group Deployment Task](../Static/3-Adding-Resource-Group-Deployment-Task.PNG "Selecting the AzureRM Resource Group Deployment task in VSTS")

## Configuring the Resource Group Deployment Task
You'll notice, now that you've added the Resource Group Deployment task, that there's more than a few parts of it to configure!
No worries though, we're going to tackle them one by one.

1. Set the `Azure Connection Type` to 'Azure Resource Manager'
2. Select your subscription from the `Azure RM Subscription` drop-down - it should match your VSTS Service Principal account.
3. Ensure the `Action` is set to 'Create or Update Resource Group'
4. Set `Resource Group` to `$(resourceGroupName)`
5. Set `Location` to wherever you please.
This demo was tested against the East US region, but should work everywhere.
6. Set `Template` to `Templates/azuredeploy.json`
This points to the path for the template so the build knows what to do.
7. Set `Template Parameters` to `Templates/azuredeploy.parameters.json`
This has some default parameters for the build - including VM Size.
8. Set `Override Template Parameters` to '-newStorageAccountName $(vmName) -dnsNameForPublicIP $(vmName) -adminUsername $(vmAdminAccount) -adminPassword (ConvertTo-SecureString -String $(vmAdminPassword) -AsPlainText -Force) -vmName $(vmName)'
*Make sure not to include the wrapping quotation marks though!*
9. Ensure `Enable Deployment Prerequisites` is checked.

Apart from Step 8, most of the steps for configuring the resource deployment are reasonably straight forward.
In that step, we're overriding the parameters as if we were at a PowerShell prompt - because, when this build task runs, we are!

So we specify that the Storage Account should be named for the VM it's attached to, as should the DNS name and, of course, the VM itself!
We give the Admin account a name (specified in the build variables) and then do some work to pass through the password as a secure string.

```PowerShell
ConvertTo-SecureString -String $(vmAdminPassword) -AsPlainText -Force
```

The secret stored in the build system is *not* stored as a secure string, just kept safe until deployment.
So, when we want to pass it in for the VM's admin account password, we need to ensure it gets converted.
Otherwise, the build will error out! 

Once we've added and configured the task for deploying the resource group, we need to do the same for the configuration!

## Adding the Task to Execute the DSC Configurations
As before, add a build step and navigate to the 'Deploy' tab.