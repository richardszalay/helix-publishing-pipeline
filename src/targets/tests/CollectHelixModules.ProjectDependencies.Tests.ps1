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

Describe "CollectHelixModules.ProjectDependencies" {

    Context "collecting helix modules for a project" {
        $projectPath = $fixtures.default.Project1

        $result = Invoke-MSBuildWithOutput -Project $projectPath -TargetName "CollectHelixModulesProjectDependencies" -OutputItem "HelixModulePaths"

        $moduleNames = $result | ForEach-Object { Split-Path $_ -Leaf }

        It "should include direct dependencies" {
            $moduleNames -contains "HelixBuild.Feature1.csproj" | Should Be $true
        }

        It "should not include indirect dependencies" {
            $moduleNames -contains "HelixBuild.Foundation1.csproj" | Should Be $false
        }
    }
}