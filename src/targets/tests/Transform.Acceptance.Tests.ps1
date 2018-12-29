. "$PSScriptRoot/utils/WebConfig.ps1"
. "$PSScriptRoot/utils/MSBuild.ps1"
. "$PSScriptRoot/utils/MSDeploy.ps1"
. "$PSScriptRoot/utils/SitecoreConfig.ps1"
. "$PSScriptRoot/utils/FileSystem.ps1"

$fixtures = @{
    default = @{
        Solution = "$PSScriptRoot\fixtures/default/HelixBuild.Sample.Web.sln";
        Project1 = "$PSScriptRoot\fixtures/default/Projects\HelixBuild.Sample.Web\code\HelixBuild.Sample.Web.csproj";
    }
    
}

$count = 1

Describe "Module Web.config transforms" {
    
    Context "building package with default settings" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false"
            
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        $webConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "Web.config")

        It "should include standard Web.config transforms from the packaged project" {
            (Get-WebConfigAppSetting $webConfigXml "Project.ConfigKey") | Should Be "Project.ConfigValue"
        }

        It "should not apply Web.config to different paths" {
            $viewsVebConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "Views/Web.config")
            (Get-WebConfigAppSetting $viewsVebConfigXml "Feature1.ConfigKey") | Should Be $null
        }

        It "should include Web.Helix.config transforms from feature modules" {
            (Get-WebConfigAppSetting $webConfigXml "Feature1.ConfigKey") | Should Be "Feature1.ConfigValue"
        }

        It "should not include Web.Helix.config transforms from indirect module dependencies" {
            (Get-WebConfigAppSetting $webConfigXml "Foundation1.ConfigKey") | Should Be $null
        }

        It "should not include merged Web.Helix.config transform in published output" {
            $packageFiles -contains "Web.Helix.config" | Should Be $false
        }
    }

    Context "building package with IncludeHelixWebConfigTransformInPackage enabled" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "Module"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "IncludeHelixWebConfigTransformInPackage" = "true"
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        It "should include merged Web.Helix.config transform in published output" {
            $packageFiles -contains "Web.Helix.config" | Should Be $true
        }
    }

    Context "building with no helix transforms" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent

        # This probably deserves it's own fixture, but I was being lazy
        Move-Item (Join-Path $projectDir "..\..\..\Features\HelixBuild.Feature1\code\Web.Helix.config") (Join-Path $projectDir "..\..\..\Features\HelixBuild.Feature1\code\Web.Helix.ignore")
        Move-Item (Join-Path $projectDir "..\..\..\Foundation\HelixBuild.Foundation1\code\Web.Helix.config") (Join-Path $projectDir "..\..\..\Foundation\HelixBuild.Foundation1\code\Web.Helix.ignore")
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "ExcludeHelixTransforms" = "true"
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $webConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "Web.config")

        It "should only apply the default transforms" {
            (Get-WebConfigAppSetting $webConfigXml "Project.ConfigKey") | Should Be "Project.ConfigValue"
        }

        AfterAll {
            $projectPath = $fixtures.default.Project1
            $projectDir = Split-Path $projectPath -Parent
            Move-Item (Join-Path $projectDir "..\..\..\Features\HelixBuild.Feature1\code\Web.Helix.ignore") (Join-Path $projectDir "..\..\..\Features\HelixBuild.Feature1\code\Web.Helix.config")
            Move-Item (Join-Path $projectDir "..\..\..\Foundation\HelixBuild.Foundation1\code\Web.Helix.ignore") (Join-Path $projectDir "..\..\..\Foundation\HelixBuild.Foundation1\code\Web.Helix.config")
        }
    }

    Context "building with no transforms" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent

        # This probably deserves it's own fixture, but I was being lazy
        Move-Item (Join-Path $projectDir "..\..\..\Features\HelixBuild.Feature1\code\Web.Helix.config") (Join-Path $projectDir "..\..\..\Features\HelixBuild.Feature1\code\Web.Helix.ignore")
        Move-Item (Join-Path $projectDir "..\..\..\Foundation\HelixBuild.Foundation1\code\Web.Helix.config") (Join-Path $projectDir "..\..\..\Foundation\HelixBuild.Foundation1\code\Web.Helix.ignore")
        Move-Item (Join-Path $projectDir "Web.Debug.config") (Join-Path $projectDir "Web.Debug.ignore")
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "ExcludeHelixTransforms" = "true";
            "ExcludeDefaultTransforms" = "true";
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        It "should succeed" {
            $packageFiles -contains "Web.config" | Should Be $true
        }

        AfterAll {
            $projectPath = $fixtures.default.Project1
            $projectDir = Split-Path $projectPath -Parent
            Move-Item (Join-Path $projectDir "..\..\..\Features\HelixBuild.Feature1\code\Web.Helix.ignore") (Join-Path $projectDir "..\..\..\Features\HelixBuild.Feature1\code\Web.Helix.config")
            Move-Item (Join-Path $projectDir "..\..\..\Foundation\HelixBuild.Foundation1\code\Web.Helix.ignore") (Join-Path $projectDir "..\..\..\Foundation\HelixBuild.Foundation1\code\Web.Helix.config")
            Move-Item (Join-Path $projectDir "Web.Debug.ignore") (Join-Path $projectDir "Web.Debug.config")
        }
    }

    Context "building with additional transforms" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "AdditionalFilesToTransform" = "App_Config\**\*.config";
            "CollectWebConfigsToTransform" = "false"
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        It "includes (Filename).(Configuration).config from the local directory" {
            $foundationConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "App_Config\Include\HelixBuild.Feature1.config")

            (Get-SitecoreSetting $foundationConfigXml "Feature1.Setting2") | Should Be "Value2"
        }

        It "includes (Filename).Helix.config from the same directory in other modules" {
            $foundationConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "App_Config\Include\HelixBuild.Feature1.config")

            (Get-SitecoreSetting $foundationConfigXml "Feature1.Setting1") | Should Be "Project"
        }

        It "prefers transform sources in the web root" {
            $viewsConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "Views\Web.config")

            (Get-WebConfigAppSetting $viewsConfigXml "ViewsConfigSetting") | Should Be "ViewsConfigValue"

            (Get-WebConfigAppSetting $viewsConfigXml "Feature1.ViewsConfigSetting") | Should Be "Feature1"
        }
    }
}