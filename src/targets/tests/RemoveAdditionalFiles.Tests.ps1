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

Describe "AdditionalFilesToRemoveFromTarget" {

    Context "include a file pattern to remove" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent

        $outDir = Join-Path $PSScriptRoot "out"
        $outBinDir = Join-Path $outDir "bin"

        if (-not (Test-Path $outBinDir))
        {
            mkdir $outBinDir
        }
        Set-Content -Path (Join-Path $outBinDir "HelixBuild.Feature2.dll") -Value "test"
        Set-Content -Path (Join-Path $outBinDir "HelixBuild.Foundation2.dll") -Value "test"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "DeployDefaultTarget" = "WebPublish";
            "WebPublishMethod" = "FileSystem";
            "PublishUrl" = $outDir;
            "DeployAsIisApp" = "false";
            "IncludeAdditionalFilesToRemoveFromTarget" = "true";
        }

        It "should remove matching files not being published" {
            (Test-Path (Join-Path $outBinDir "HelixBuild.Feature2.dll")) | Should Be $false
        }

        It "should not remove matching files being published" {
            (Test-Path (Join-Path $outBinDir "HelixBuild.Feature1.dll")) | Should Be $true
        }

        It "should not remove unmatched files" {
            (Test-Path (Join-Path $outBinDir "HelixBuild.Foundation2.dll")) | Should Be $true
        }
    }
}