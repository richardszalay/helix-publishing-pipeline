This is proof of concept prototype for seamlessly integrating the Helix solution structure with the Web Publishing Pipeline feature of .NET and Visual Studio. Specifically, it attempts to merge Helix modules from lower layers (foundation, features) with the top layer (project) when it comes to publishing.

The desire for this project comes from Helix itself. While the Helix recommendation states that 

Design principles:

* Adding these targets to a Project should provide as much functionality as possible (ie. sensible defaults)
* Stick to WPP integration points wherever possible
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
- [ ] Allow modules to contribute Web.config transforms
- [ ] Provide PowerShell Cmdlets for publishing that support publishing specific types of content (eg. content only, to avoid recycling the app pool)

Secondary feature goals:

- [ ] Maintain "Publish from Visual Studio compatibility"
- [ ] Provide content type skipping as MSBuild functionality so it can be supported without the PowerShell Cmdlets
- [ ] Decide on whether recursive "dependent module" support is feasible, or whether it should use folder structure conventions
- [ ] Allow modules to contribute any .config transform