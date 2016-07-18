---
Tags: concept
      vsts
      build
---
# Build Variables
Build variables are where most of the not-magic happens in our build process.
They're what we're using (in this case) to deploy our infrastructure.

However, in a true infrastructure-as-code deployment, we'd use *much* fewer build variables - essentially, only keeping our secrets (user passwords, API keys, etc) in the build variables.

The reason for this is twofold:

1. Build Variables can't transfer to a different build system easily.
If you ever decide to use [AppVeyor](http://www.appveyor.com/), [Travis CI](https://travis-ci.org/), [Jenkins](https://jenkins.io/index.html), or another continuous integration build system, you will have to define all of the same variables for those builds as well.
2. Changes to Build Variables don't reside in your source control repository and can't be versioned with the templates, configurations, and helper scripts.
This means, necessarily, adding a build variabls changelog to your source control repository or splitting your source of truth for builds. While the VSTS build system **does** allow you to save each edit to the system and include a comment - somewhat like a source control commit - again, this data can't come with you if you change systems. It's also a place to look for changes to your infrastructure *other* than your primary source control.

With those caveats out of the way, let's dive a bit deeper into considerations for the build variables with regard to this project.

## Naming Build Variables
In general, it's best to give our build variables descriptive names.
The person defining the build may not always be the person editing or executing the build so it's good practice to ensure someone can tell at a glance what the variables are used for.

The naming convention of existing build variables in VSTS is [`camelCase`](https://en.wikipedia.org/wiki/CamelCase).

## Allow at Queue Time
Any variable which you'd like to be able to set at each deploy should be marked for `Allow at Queue Time`.
This ensures you can override the build's default value for this variable at deployment.

This is particularly important for things like passwords, API keys, and names. 
For example, if deploying a test version of the gallery, I may not want to use my production credentials and I may want to identify the resource group as one for testing.

Again though, aside from secrets, these changes *should* be made in source control and pushed to the repository if we're following best practices.

## Secrets
Marking a Build Variable as a secret ensures that the variable is encrypted at rest.
For more on the security of secrets in VSTS, see this [reference](https://www.visualstudio.com/en-us/docs/build/define/variables#secret-variables).

We use secrets for our builds because there is some information we do **not** want in source control - namely, passwords and keys.
Source control for internal projects may (should!) have access control policies, but storing passwords or keys in plain text is still probably not the best idea.

For open source projects, passwords and keys **must** be kept secure and outside of source control because there isn't any access control on viewing the source code. 