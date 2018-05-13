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

Describe "CollectFilesFromHelixModules.Additional" {

    Context "when additional files are configured" {
        $projectPath = $fixtures.default.Project1

        $result = Invoke-MSBuildWithOutput -Project $projectPath -Properties @{
            "IncludeAdditionalHelixModulesContent" = "true";
        } -TargetName "CollectFilesFromHelixModulesAdditional" -OutputItem "FilesForPackagingFromHelixModules -> '%(DestinationRelativePath)'"

        It "should include matching files" {
            $result -contains "assets\feature1.js" | Should Be $true
        }
    }

    Context "when additional files are not configured" {
        $projectPath = $fixtures.default.Project1

        $result = Invoke-MSBuildWithOutput -Project $projectPath -Properties @{
            "IncludeAdditionalHelixModulesContent" = "false";
        } -TargetName "CollectFilesFromHelixModulesAdditional" -OutputItem "FilesForPackagingFromHelixModules -> '%(DestinationRelativePath)'"

        It "should not include additional files" {
            $result -contains "assets\feature1.js" | Should Be $false
        }
    }
}