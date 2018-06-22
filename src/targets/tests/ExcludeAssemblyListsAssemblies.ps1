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

Describe "ExcludeSitecoreAssemblyLists" {

    Context "excluding a single assembly list" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "IncludeFeatureAssemblyList" = "true";
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        It "should exclude all assemblies" {
            $packageFiles -contains "bin\HelixBuild.Feature1.dll" | Should Be $false
        }
    }

    Context "specifying whitelisted assemblies" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "IncludeFeatureAssemblyList" = "true";
            "WhitelistFeatureAssembly" = "true"
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        It "should include whitelisted assemblies" {
            $packageFiles -contains "bin\HelixBuild.Feature1.dll" | Should Be $true
        }
    }

    Context "excluding multiple assembly lists" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
            "IncludeFeatureAssemblyList" = "true";
            "IncludeFoundationAssemblyList" = "true";
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        It "should exclude all assemblies from all lists" {
            $packageFiles -contains "bin\HelixBuild.Feature1.dll" | Should Be $false
            $packageFiles -contains "bin\HelixBuild.Foundation1.dll" | Should Be $false
        }
    }

}