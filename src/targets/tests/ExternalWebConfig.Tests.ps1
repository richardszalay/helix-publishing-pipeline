. "$PSScriptRoot/utils/WebConfig.ps1"
. "$PSScriptRoot/utils/MSBuild.ps1"
. "$PSScriptRoot/utils/MSDeploy.ps1"

$fixtures = @{
    default = @{
        Solution = "$PSScriptRoot\fixtures/default/HelixBuild.Sample.Web.sln";
        Project1 = "$PSScriptRoot\fixtures/default/Projects\HelixBuild.Sample.Web\code\HelixBuild.Sample.Web.csproj";
    }
    
}

$count = 1

Describe "External Web.config" {

    Context "building package with an external Web.config set" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "Module"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "ExternalWebConfigLocation" = "$PSScriptRoot\fixtures\ExternalWebConfig\Web.config"; # Test property that injects @(ReplacementFilesForPackaging)
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $webConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "Web.config")

        It "should apply transforms to the external Web.config" {
            (Get-WebConfigAppSetting $webConfigXml "ExternalWebConfig") | Should Be "External"
        }

        It "should include standard Web.config transforms from the packaged project" {
            (Get-WebConfigAppSetting $webConfigXml "Project.ConfigKey") | Should Be "Project.ConfigValue"
        }

        It "should include Web.Helix.config transforms from feature modules" {
            (Get-WebConfigAppSetting $webConfigXml "Feature1.ConfigKey") | Should Be "Feature1.ConfigValue"
        }
    }
}