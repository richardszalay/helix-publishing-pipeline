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

Describe "Module configuration" {

    Context "building package with default settings" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "Module"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "IncludeAdditionalHelixModulesContent" = "true";
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageParameters = Get-MSDeployPackageParameters $packageFilename
        $packageParameterNames = $packageParameters.Keys

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        It "should include web deploy parameters from the packaged project" {
            $packageParameterNames -contains "Project-Parameter1" | Should Be $true
        }

        It "should include web deploy parameters from direct module dependencies" {
            $packageParameterNames -contains "Feature1-Parameter1" | Should Be $true
        }

        It "should not include web deploy parameters from indirect module dependencies" {
            $packageParameterNames -contains "Foundation1-Parameter1" | Should Be $false
        }

        It "should include content from the packaged project" {
            $packageFiles -contains "App_Config\Include\HelixBuild.Sample.Web.config" | Should Be $true
        }

        It "should include content from direct module dependencies" {
            $packageFiles -contains "App_Config\Include\HelixBuild.Feature1.config" | Should Be $true  
        }

        It "should include additional module content that have been specified by path" {
            $packageFiles -contains "assets\feature1.js" | Should Be $true
        }

        It "should not include additional module content that have been specified by path from indirect module dependencies" {
            $packageFiles -contains "assets\foundation.js" | Should Be $false
        }

        It "should not include content from indirect module dependencies" {
            $packageFiles -contains "App_Config\Include\HelixBuild.Foundation1.config" | Should Be $false
        }

        It "should not include Web.config from the packaged project" {
            $packageFiles -contains "Web.config" | Should Be $false
        }

        It "should not include other Web.config from the packaged project" {
            $packageFiles -contains "Views\Web.config" | Should Be $false
        }

        # The default pipeline excludes config transforms, even if they are marked as Content
        It "should not prevent transforms from being excluded" {
            $packageFiles -contains "Web.Release.config" | Should Be $false
        }

        It "should prevent downstream publish profiles from being imported" {
            # If the publish succeeds then this test passes, as Feature1 contains a malformed Package.pubxml
            $true | Should Be $true
        }
    }
}