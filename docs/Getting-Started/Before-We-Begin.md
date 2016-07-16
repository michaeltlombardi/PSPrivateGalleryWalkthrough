---
Tags: Getting-Started
      prerequisites
---
# Before We Begin
Before we can deploy a PowerShell Private Gallery, we need to nail down a few prerequisites.

## Prerequisites
1. An Azure account
2. A Visual Studio Team Services account
3. A fork of this repository

## Getting an Azure Account
If you don't already have a Microsoft Azure account, you can sign up for one [here](https://azure.microsoft.com/en-us/free/).
This option will sign you up for an Azure Account with a $200 credit - that credit expires at the end of your first month though, so be aware of this!

If you're a student, you may want to use your [DreamSpark account](https://www.dreamspark.com/Product/Product.aspx?productid=99) with Azure.

If you're an MSDN subscriber, you *definitely* want to hook up your MSDN account to Azure - you get [up to $150 per month in credits](https://azure.microsoft.com/en-us/pricing/member-offers/msdn-benefits-details/)!

## Setting up Visual Studio Team Services
The first thing to do is to [sign up](https://www.visualstudio.com/en-us/docs/setup-admin/team-services/sign-up-for-visual-studio-team-services).
Once you're signed up, you'll need to create a team project - for the rest of the Walkthrough we're going to assume that you've called the project 'PSPrivateGallery'.
The URL for this should look something like `https://youraccountname.visualstudio.com/PSPrivateGallery`.

## Forking this Repository
To [fork](../Concepts/Forking.md) this repository, first go to the repository's [page](https://github.com/michaeltlombardi/PSPrivateGalleryWalkthrough) on Github.
Then click the `Fork` button in the top right corner.
You should now have a fork of the repository in your own account.

## PowerShell Modules
You'll need the AzureRM PowerShell modules installed to create your VSTS Service Principal.
If you have PowerShell v5, this is relatively straightforward:
```powershell
Find-Module AzureRM | Install-Module -Force -Scope CurrentUser
```

**Note:** If you'd like to install the module for everyone on the computer, you can drop `-Scope CurentUser` - however, you'll need to run the command with administrator rights.

## Create a Visual Studio Team Services Service Principal Account
In order to connect our Azure account to VSTS, we'll need to generate a Service Principal Account.
The easiest way is to follow the directions [here](https://blogs.msdn.microsoft.com/visualstudioalm/2015/10/04/automating-azure-resource-group-deployment-using-a-service-principal-in-visual-studio-online-buildrelease-management/) from the MSDN Blog.
All we've done here is to pull the script into our script folder (Add-AzureServicePrincipal.ps1).

The short version, if you just want to get started, is to run that script on your local machine.
You'll need to know your Azure Subscription name and specify a password for the Service Principal.

For example (assuming you've opened a powershell prompt at the root of your local clone of this repository:
```powershell
Push-Location .\Scripts
.\Add-AzureServicePrincipal.ps1 -subscriptionName 'MySubName' -Password 'SomeS35ure Password, hahahah! :D'
Pop-Location
```

You should get output like the block below; Save it in a notepad! You're going to need it for Step Two!
```
***************************************************************************
Connection Name: MySubName(SPN)
Subscription Id: dbcdf31c-a2fb-4e27-a0ec-0af48fdb03ac
Subscription Name: MySubName
Service Principal Id: 1670693b-0c9e-4782-ac17-4e2c27064995
Service Principal key: <Password that you typed in>
Tenant Id: 8494debb-26c9-47c3-85bf-35ee23d3ae01
***************************************************************************
```

Save that output! We're going to use it in 
## Finally!
That's it, you've got all the prerequisites for this walkthrough now.
Next up: adding your fork to VSTS. 