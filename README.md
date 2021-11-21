# Helix Publishing Pipeline

[![Build status](https://ci.appveyor.com/api/projects/status/y0reigvxgct4vmgq/branch/master?svg=true)](https://ci.appveyor.com/project/richardszalay/helix-publishing-targets/branch/master) [![NuGet](https://img.shields.io/nuget/v/RichardSzalay.Helix.Publishing.WebRoot.svg)][1]

Helix Publishing Pipeline (HPP) allows Helix solutions to be published as a single unit, with content from modules (like views and config patches) being automatically included. It also contains optimisations and guidance around local development deployments.

Because the project extends the standard Web Publishing Pipeline it should work with any supported target (package, file system, Azure, Docker) via either Visual Studio or the command line.

## Example

The [Helixbase](https://github.com/muso31/Helixbase) project makes use of a number of HPP features, and so acts a reference to how it can be integrated.

## Installation

Before you begin, choose a project that will act as the web root (i.e., owns the `Web.config`) for publishing. For solutions with multiple "Project" modules, it's best to explicitly create a "Website" project.

Once that's done, there are two steps to enable the Helix Publish Pipeline:

1. Install the [`RichardSzalay.Helix.Publishing.WebRoot`][1] NuGet package in the web root project.
2. Add a project reference to all Project, Feature, and Foundation module projects, or apply auto-discovery as described below.

### Auto-discovering modules

Since Helix solutions tend to expand to a large number of modules, it may be preferable to reference them dynamically. To do this, remove any explicit project references from your web root and add something like the code below to the a `Directory.Build.props` file in your website project directory. Doing it this way will prevent Visual Studio from expanding the globs when you rename a project.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">

  <ItemGroup>
    <ProjectReference Include="..\Foundation\*\code\*.csproj" />
    <ProjectReference Include="..\Feature\*\code\*.csproj" />
    <ProjectReference Include="..\Project\*\code\*.csproj" />
  </ItemGroup>

</Project>
```

### Publishing on build

To trigger a publish after each build, add the following to your web root `.csproj` (anywhere before the `Web.Publishing.targets` import):

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

The example above triggers the `Local` publish profile when building as `Debug` within Visual Studio. It has been designed to minimise impact on build timings.

This behavior is currently described via opt-in guidance, but may be configured automatically in a future release.

NOTE: When publishing to `FileSystem`, Helix Publishing Pipeline detects unchanged `Web.config` transformation outputs and skips them to prevent an unnecessary app pool recycle.

### Excluding Sitecore assemblies

In many cases it may be desirable to exclude from publish the assemblies that ship with Sitecore, either to reduce the size of the deployment artifact, or to reduce the chance of overriding assemblies with incorrect versions.

Helix Publishing Pipeline supports excluding Sitecore assemblies either individually, from Sitecore Assemblies NuGet packages (available on the [`sc-packages`](https://sitecore.myget.org/gallery/sc-packages) feed, e.g. [`Sitecore.Assemblies.Platform`](https://sitecore.myget.org/feed/sc-packages/package/nuget/Sitecore.Assemblies.Platform)) or from assembly lists (text lists for each release, available from SDN).

PDB and XML documentation files are also excluded.

To exclude assemblies from publish, you can create a [`.wpp.targets` file](https://docs.microsoft.com/en-us/previous-versions/aspnet/ff398069(v%3Dvs.110)#creating-a-wpptargets-file) and use HPP-provided item groups in any of the following ways:

1. Reference a `Sitecore.Assemblies` NuGet package on your project, and use the `SitecoreAssemblies` item group which it adds to populate `SitecoreAssembliesToExclude`.
1. Download assembly lists and reference them in `SitecoreAssemblyListsToExclude`.
1. Add individual assemblies via `SitecoreAssembliesToExclude`.

```xml
<!-- In ProjectName.wpp.targets or PublishProfile.wpp.targets -->
<ItemGroup>
  <!-- Requires NuGet reference to Sitecore.Assemblies.Platform or another Assemblies package -->
  <SitecoreAssembliesToExclude Include="@(SitecoreAssemblies)" />

  <!-- Assembly lists -->
  <SitecoreAssemblyListsToExclude Include="Assembly Lists\Sitecore.Platform.Assemblies 9.0.1 rev. 171219.csv" />
  <SitecoreAssemblyListsToExclude Include="Assembly Lists\Sitecore.XConnect.Platform.Assemblies 9.0.1 rev. 171219.csv" />

  <!-- Or individual assemblies -->
  <SitecoreAssembliesToExclude Include="Sitecore.Kernel.dll" />
</ItemGroup>>
```

Individual assemblies can also be whitelisted (for example, if a patched version is included with the application):

```xml
<!-- In ProjectName.wpp.targets or PublishProfile.wpp.targets -->
<ItemGroup>
  <SitecoreAssembliesToInclude Include="System.Web.Mvc.dll" />/>
</ItemGroup>>
```

Another option for white-listing multiple assemblies when applying a Sitecore patch is to create an ItemGroup with the items and metadata 

```xml
<ItemGroup>
  <SitecoreHotfixAssemblies Include="Sitecore.ContentSearch.dll">
      <Name>Sitecore.ContentSearch.dll</Name>
      <Version>5.0.0.0</Version>
      <FileVersion>5.0.0.0</FileVersion>
      <InfoVersion>5.0.0-r00294</InfoVersion>
  </SitecoreHotfixAssemblies> 
  <SitecoreHotfixAssemblies Include="Sitecore.Kernel.dll">
      <Name>Sitecore.Kernel.dll</Name>
      <Version>13.0.0.0</Version>
      <FileVersion>13.0.0.0</FileVersion>
      <InfoVersion>13.0.0-r00755</InfoVersion>
  </SitecoreHotfixAssemblies>
</ItemGroup>
```

The benefits of this method are:

1. Allows fine-grained control over the version of the dll that's white-listed
2. Allows for the `ItemGroup` to be packaged up into a `.targets` file (which could be included in a Nuget package) 
3. Cleaner exclusion rule which looks like this:

```xml
<ItemGroup>
  <!-- Requires NuGet reference to Sitecore.Assemblies.Platform or another Assemblies package -->
  <SitecoreAssembliesToExclude Include="@(SitecoreAssemblies)" 
                               Exclude="@(SitecoreHotfixAssemblies)" />
</ItemGroup>
```

## Extensibility

Unless otherwise specified, customisations should be either made to `ProjectName.wpp.targets` (to apply to all profiles) or `PublishProfileName.wpp.targets` (to apply to a single profile).

> Please note that the `PublishProfileName.wpp.targets` must be in the same folder as the `PublishProfileName.pubxml` file and the `ProjectName.wpp.targets` must be in the same folder as your .csproj.

### Defining `Web.config` transforms

Every module can define their own `Web.Helix.config` transform file to apply config transforms to the web root's `Web.config` file during publishing.

#### Delayed transformation

Some environments prefer to keep the official `Web.config` file with the target Sitecore installation.

To support deploy-time transforms (e.g., Slow Cheetah, VSTS, Octopus), the combined `Web.Helix.config` transform can be optionally included in the publish output:

```xml
<!-- In ProjectName.wpp.targets or PublishProfile.wpp.targets -->
<PropertyGroup>
  <IncludeHelixWebConfigTransformInPackage>true</IncludeHelixWebConfigTransformInPackage>
</PropertyGroup>

<!-- Optionally omit the project's Web.config from publishing -->
<ItemGroup>
  <ExcludeFromPackageFiles Include="Web.config" />
</ItemGroup>
```

For local development scenarios, the transform can also be applied to an external `Web.config`. The transformed output will be published instead of the project's `Web.config`:

```xml
<!-- In ProjectName.wpp.targets or PublishProfile.wpp.targets -->
<ItemGroup>
  <ReplacementFilesForPackaging Include="c:\inetpub\wwwroot\Sitecore\Web.config">
    <DestinationRelativePath>Web.config</DestinationRelativePath>
  </ReplacementFilesForPackaging>
</ItemGroup>
```

### Defining Web Deploy parameters

Every module can define their own `Parameters.xml` file in the root of the project, which will all be merged during publishing.

Parameters defined in MSBuild using `MsDeployDeclareParameters` or `MSDeployParameterValue` items are still supported in the web root project, but cannot be defined at the module level.

### Including additional content

The default behavior is to include all project items marked as `Content` (in their file properties). If your builds dynamically generate files, they can be included in the publish using standard WPP extensibility.

To include additional content under the project directory by glob, define `AdditionalFilesForPackagingFromHelixModules`:

```xml
<!-- In ProjectName.wpp.targets or PublishProfile.wpp.targets -->
<ItemGroup>
  <!-- Escaping is required -->
  <AdditionalFilesForPackagingFromHelixModules Include="$([MSBuild]::Escape('assets\**\*'))" />
</ItemGroup>
```

For advanced scenarios, such as when the source and target directories don't match exactly, specify both a `SourcePath` and `TargetPath`. `TargetPath` can refer to content metadata using the `^(Metadata)` syntax and can also refer to any metadata from the relative module using `^(HelixModule.Metadata)`:

```xml
<!-- In ProjectName.wpp.targets or PublishProfile.wpp.targets -->
<ItemGroup>
  <AdditionalFilesForPackagingFromHelixModules Include="Serialization">
    <SourcePath>..\serialization\**\*.yml</SourcePath>
    <TargetPath>App_Data\unicorn\^(HelixModule.Filename)\^(RecursiveDir)^(Filename)^(Extension)</TargetPath>
  </AdditionalFilesForPackagingFromHelixModules>
</ItemGroup>
```

A list of standard file metadata names can be found at [MSBuild well-known item metadata](https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-well-known-item-metadata), and additional module metadata can be specified with the `ProjectReference`:


```xml
<ItemGroup>
  <ProjectReference Include="..\Foundation\*\code\*.csproj">
    <!-- Can be used in a TargetPath using ^(HelixModule.Layer) -->
    <Layer>Foundation</Layer>
  </ProjectReference>
</ItemGroup>
```

Alternatively, additional module metadata can be extracted based on module naming conventions by defining a `HelixModuleMetadataPatterns` that specifies a Regular Expression with named groups:

```xml
<ItemGroup>
  <!-- eg. AwesomePlatform.Feature.Hero -->
  <HelixModuleMetadataPatterns Include="Convention">
    <!-- Now available as ^(HelixModule.Namespace), ^(HelixModule.Layer), and ^(HelixModule.Module) -->
    <Pattern>^(?'Namespace'.+)\.(?'Layer'.+?)\.(?'Module'.+)$</Pattern>
    <!-- Uncomment the following line to use a different Source to match the regex upon (e.g. FileName) -->
    <!-- <SourceMetadataName>FileName</SourceMetadataName> -->
  </HelixModuleMetadataPatterns>
</ItemGroup>
```

NOTE: `Web.config` files contained in modules are intentionally skipped to avoid issues with long paths as described by [#9](https://github.com/richardszalay/helix-publishing-pipeline/issues/9). This restriction only affects `Web.config` files, not Sitecore config files, and will be removed once a suitable workaround is place.

### Removing additional files

It's quite common, particularly in development, to rename projects and config files. Unfortunately these typically remain in the deployment folder unless manually removed and can cause problems. Since the only built in option (DeleteExistingFiles) deletes _all_ target files, including `/sitecore` and always triggering an AppPool recycle, Helix Publishing Pipeline provides support for deleting target files specified by a pattern.

The implementation only deletes additional files when they exist, skipping unnecessary AppPool recycles when no assemblies have changed.

To use it, define `AdditionalFilesToRemoveFromTarget` with a file pattern in the `TargetPath` metadata:

```xml
<!-- In ProjectName.wpp.targets or PublishProfile.wpp.targets -->
<ItemGroup>
  <AdditionalFilesToRemoveFromTarget Include="ContosoAssemblies">
    <TargetPath>bin\Contoso.*.dll</TargetPath>
  </AdditionalFilesToRemoveFromTarget>
  <AdditionalFilesToRemoveFromTarget Include="ContosoConfig">
    <TargetPath>App_Config\**\Contoso.*.config</TargetPath>
  </AdditionalFilesToRemoveFromTarget>
</ItemGroup>
```

This feature is only currently supported when publishing to a FileSystem target, though a future release may support generating MSDeploy skip rules.

### Advanced scenarios

Helix Publishing Pipeline has been developed using standard MSBuild conventions. As such, all functionality can be customised or disabled entirely. Review the [target files](src/targets) for specifics.

[1]: https://www.nuget.org/packages/RichardSzalay.Helix.Publishing.WebRoot/

# Contributors

Many thanks to all the members of the community that have contributed PRs to this project:

* [bartlomiejmucha](https://github.com/bartlomiejmucha)
* [BasLijten](https://github.com/BasLijten)
* [coreyasmith](https://github.com/coreyasmith)
* [jeneaux](https://github.com/jeneaux)
* [luuksommers](https://github.com/luuksommers)
