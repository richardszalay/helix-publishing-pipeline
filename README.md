[![Build status](https://ci.appveyor.com/api/projects/status/y0reigvxgct4vmgq/branch/master?svg=true)](https://ci.appveyor.com/project/richardszalay/helix-publishing-targets/branch/master)

Helix Publishing Pipeline allows Helix solutions to be published as a single unit, with content (like views and config patches) from modules being automatically included. It also contains optimisations and guidance around local development deployments.

Because the project extends the standard Web Publishing Pipeline it should work with any supported target (package, file system, Azure, Docker) via either Visual Studio or the command line.

## Installation

This repository contains a [sample solution](https://github.com/richardszalay/helix-publishing-pipeline/tree/master/examples) with everything pre-configured which can be used as a reference.

Before you begin, choose a project that will act as the web root (ie. owns the Web.config) for publishing. For solutions with multiple "Project" modules, it's best to explicitly create a "Website" project.

Once that's done, there are two steps to enable the Helix Publish Pipeline:

* Install the `RichardSzalay.Helix.Publishing.WebRoot` package to the web root project
* Add a project reference to all Project, Feature, and Foundation module projects, or apply auto-discovery as described below

### Auto-discovering modules

Since Helix solutions tend to expand to a large number of modules, it may be preferable to reference them dynamically. To do this, add the following to the web root csproj file instead of adding references to the modules:

```xml
<ItemGroup>
  <ProjectReference Include="..\Foundation\*\code\*.csproj" />
  <ProjectReference Include="..\Feature\*\code\*.csproj" />
  <ProjectReference Include="..\Project\*\code\*.csproj" />
</ItemGroup>
```

### Publishing on build

To trigger a publish after each build, add the following to your web root csproj (anywhere before the `Web.Publishing.targets` import):

```xml
<PropertyGroup>
  <DisableFastUpToDateCheck>true</DisableFastUpToDateCheck>
  <PublishProfile>Local</PublishProfile>
</PropertyGroup>

<!-- The rest can go into ProjectName.wpp.targets if you prefer -->
<PropertyGroup>
  <AutoPublish Condition="'$(AutoPublish)' == '' and '$(Configuration)' == 'Debug' and '$(BuildingInsideVisualStudio)' == 'true' and '$(PublishProfile)' != ''">true</AutoPublish>

  <AutoPublishDependsOn Condition="'$(AutoPublish)' == 'true'">
    $(AutoPublishDependsOn);
    WebPublish
  </AutoPublishDependsOn>
</PropertyGroup>

<Target Name="AutoPublish" AfterTargets="Build" DependsOnTargets="$(AutoPublishDependsOn)">
</Target>
```

The example above triggers the 'Local' publish profile when building as 'Debug' within Visual Studio. It has been designed to minimise impact on build timings.

This behavior is currently described via opt-in guidance, but may be configured automatically in a future release.

NOTE: When publishing to `FileSystem`, Helix Publishing Pipeline detects unchanged Web.config transformation outputs and skips them to prevent an unnecessarily app pool recycle.

## Extensibility

### Defining Web.config transforms

Every module can define their own `Web.Helix.config` transform file to apply config transforms to the web root's Web.config file during publishing.

### Defining Web Deploy parameters

Every module can define their own `Parameters.xml` file in the root of the project, which will all merged during publishing.

Parameters defined in MSBuild using `MsDeployDeclareParameters` or `MSDeployParameterValue` items are still supported in the web root project, but cannot be defined at the module level. 

### Including additional content

The default behavior is to include all project items marked as `Content` (in their file properties). If your builds dynamically generate files, they can be included in the publish using standard WPP extensibility. 

Support for including Helix module module files by convention/glob will be described at a future time.

NOTE: Web.config files contained in modules are intentionally skipped to avoid issues with long paths as described by [#9](https://github.com/richardszalay/helix-publishing-pipeline/issues/9). This restriction only affects Web.config files, not Sitecore config files, and will be removed once a suitable workaround is place.

### Advanced scenarios

Helix Publishing Pipeline has been developed using standard MSBuild conventions. As such, all functionality can be customised or disabled entirely. Review the [target files](https://github.com/richardszalay/helix-publishing-pipeline/tree/master/src/targets) for specifics.
