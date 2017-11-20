[![Build status](https://ci.appveyor.com/api/projects/status/y0reigvxgct4vmgq/branch/master?svg=true)](https://ci.appveyor.com/project/richardszalay/helix-publishing-targets/branch/master)

This project simplifies the publishing of Sitecore Helix solutions by integrating the web project _dependencies_ into the standard ASP.NET publishing pipeline.

# Features

There's nothing to configure. Adding the appropriate NuGet package automatically enables the following behavior to the standard ASP.NET "Publish" process:

| Feature | Enabled by default |
| ------ | ------ |
| Content in dependent projects is included in the publish | Yes |
| Web Deploy parameters (Parameters.xml) from dependent projects are included in the publish | Yes |
| Web.config transforms (Web.Helix.config) from dependent projects are applied to project's Web.config | WebRoot package only |
| Web.config and Views/Web.config are excluded from publish | Module package only |
| Publishing does not cause dependent projects to also independently publish  | Yes |

Essentially:

1. The project in your solution that will publish the Web.config (if any) should use the WebRoot configuration
2. Any other projects that you want to enable the publishing behavior for (eg. Helix Projects) should use the Module configuration
3. Any modules that don't need to be published (or for which the built in publishing is sufficient) can remain as-is.

# Installation

`PM> Install-Package RichardSzalay.Helix.Publishing.WebRoot`

or

`PM> Install-Package RichardSzalay.Helix.Publishing.Module`

# Roadmap

* NuGet packages
* Automatic publishing on build (opt-in)
* Optimising publishing for particular development scenarios (content-only, exclude razor, exclude config, etc)
* Document limitations as well as compatibility with Habitat, Unicorn, and TDS

# Background and design

The desire for this project comes from Helix itself. While the Helix recommendation states that features should be self contained in their own project, no packaging/deployment functionality is included in the reference implementation and web publishing in Visual Studio doesn't have native support for web project references.

This system assumes that you intend to package/deploy all modules with the project, as opposed to individually which you can do already. For the short term it will also assume that _all_ modules will ship with _all_ projects, as opposed to only shipping _dependent_ modules.

Design principles:

* Adding these targets to a Project should provide as much functionality as possible (ie. sensible defaults)
* Everything should work with any publishing method (Web Deploy, Package, File System). Stick to WPP integration points wherever possible. 
* Everything should be extensible
* Everything should be test driven

Primary use cases that I'm looking to actively support:

* Packaging a project module
* Publishing a project module to a remote server
* Publishing a project/feature module to a local folder/website

Secondary use cases that I'll look to support later:

* Packaging a feature module
* Publishing a feature module to a remote server

Primary feature goals:

- [x] Include content / config from dependent modules
- [x] Allow modules to contribute Web Deploy parameter definitions
- [x] Allow modules to contribute Web.config transforms
- [ ] Provide PowerShell Cmdlets for publishing that support publishing specific types of content (eg. content only, to avoid recycling the app pool)

Secondary feature goals:

- [ ] Maintain "Publish from Visual Studio compatibility"
- [ ] Provide content type skipping as MSBuild functionality so it can be supported without the PowerShell Cmdlets
- [ ] Decide on whether recursive "dependent module" support is feasible, or whether it should use folder structure conventions
- [ ] Allow modules to contribute any .config transform
