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

## Finally!
That's it, you've got all the prerequisites for this walkthrough now.
Next up: adding your fork to VSTS. 