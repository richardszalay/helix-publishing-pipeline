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

Describe "CollectHelixModuleMetadata" {

    Context "when defining regex patterns as HelixModuleMetadataPatterns" {
        $projectPath = $fixtures.default.Project1

        $items = @(Invoke-MSBuildWithOutput -Project $projectPath -TargetName "CollectHelixModuleMetadata" -OutputItem "HelixModulePaths")

        It "adds matching named groups as metadata to HelixModulePaths" {
            $items.Namespace | Should Be "HelixBuild"
            $items.Layer | Should Be "Feature"
            $items.Number | Should Be "1"
        }
    }
}