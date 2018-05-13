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

Describe "WebRoot configuration" {

    Context "building package with default settings" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageParameters = Get-MSDeployPackageParameters $packageFilename
        $packageParameterNames = $packageParameters.Keys

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        $webConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "Web.config")

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

        It "should not include content from indirect module dependencies" {
            $packageFiles -contains "App_Config\Include\HelixBuild.Foundation1.config" | Should Be $false
        }

        It "should include Web.config from the packaged project" {
            (Get-WebConfigAppSetting $webConfigXml "HelixProject") | Should Be "Sample.Web"
        }

        It "should not include include Web.config from direct module dependencies" {
            (Get-WebConfigAppSetting $webConfigXml "HelixBuild.Feature1") | Should Be $null
        }

        It "should not include include Web.config from indirect module dependencies" {
            (Get-WebConfigAppSetting $webConfigXml "HelixBuild.Foundation1") | Should Be $null
        }

        It "should include standard Web.config transforms from the packaged project" {
            (Get-WebConfigAppSetting $webConfigXml "Project.ConfigKey") | Should Be "Project.ConfigValue"
        }

        It "should include Web.Helix.config transforms from feature modules" {
            (Get-WebConfigAppSetting $webConfigXml "Feature1.ConfigKey") | Should Be "Feature1.ConfigValue"
        }

        It "should not include merged Web.Helix.config transform" {
            $packageFiles -contains "Web.Helix.config" | Should Be $false
        }

        It "should not include Web.Helix.config transforms from indirect module dependencies" {
            (Get-WebConfigAppSetting $webConfigXml "Foundation1.ConfigKey") | Should Be $null
        }
    }

    Context "building package twice with unchanged Web.config" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent

        $outDir = Join-Path $PSScriptRoot "out"

        $webConfigInputFile = Join-Path $projectDir "Web.config"
        $webConfigOutputFile = Join-Path $outDir "Web.config"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "DeployDefaultTarget" = "WebPublish";
            "WebPublishMethod" = "FileSystem";
            "PublishUrl" = $outDir;
            "DeployAsIisApp" = "false";
        }

        $firstWrite = (Get-Item $webConfigOutputFile).LastWriteTime

        (Get-ChildItem $webConfigInputFile).LastWriteTime = Get-Date

        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "DeployDefaultTarget" = "WebPublish";
            "WebPublishMethod" = "FileSystem";
            "PublishUrl" = $outDir;
            "DeployAsIisApp" = "false";
            "EnablePackageProcessLoggingAndAssert" = "true";
        }

        It "should not deploy the config file twice" {
            $result = (Get-Item $webConfigOutputFile).LastWriteTime

            $result | Should Be $firstWrite
        }
    }

    Context "building package twice with unchanged Web.config and DeleteExistingFiles enabled" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent

        $outDir = Join-Path $PSScriptRoot "out"

        $webConfigInputFile = Join-Path $projectDir "Web.config"
        $webConfigOutputFile = Join-Path $outDir "Web.config"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "DeployDefaultTarget" = "WebPublish";
            "WebPublishMethod" = "FileSystem";
            "PublishUrl" = $outDir;
            "DeployAsIisApp" = "false";
            "DeleteExistingFiles" = "true";
        }

        $firstWrite = (Get-Item $webConfigOutputFile).LastWriteTime

        (Get-ChildItem $webConfigInputFile).LastWriteTime = Get-Date

        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "DeployDefaultTarget" = "WebPublish";
            "WebPublishMethod" = "FileSystem";
            "PublishUrl" = $outDir;
            "DeployAsIisApp" = "false";
            "EnablePackageProcessLoggingAndAssert" = "true";
            "DeleteExistingFiles" = "true";
        }

        It "should deploy the config file twice" {
            $result = (Get-Item $webConfigOutputFile).LastWriteTime

            $result | Should Not Be $firstWrite
        }
    }

    Context "building package twice with changed Web.config" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent

        $outDir = Join-Path $PSScriptRoot "out"

        $webConfigInputFile = Join-Path $projectDir "Web.config"
        $webConfigOutputFile = Join-Path $outDir "Web.config"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "DeployDefaultTarget" = "WebPublish";
            "WebPublishMethod" = "FileSystem";
            "PublishUrl" = $outDir;
            "DeployAsIisApp" = "false";
        }

        $firstWrite = (Get-Item $webConfigOutputFile).LastWriteTime

        (Get-ChildItem $webConfigInputFile).LastWriteTime = Get-Date

        Invoke-MSBuild -Project $projectPath -Properties @{
            "HelixTargetsConfiguration" = "WebRoot"; # This is only supported by the test fixture
            "Configuration" = "Release"; # Release has different transforms
            "DeployOnBuild" = "true";
            "DeployDefaultTarget" = "WebPublish";
            "WebPublishMethod" = "FileSystem";
            "PublishUrl" = $outDir;
            "DeployAsIisApp" = "false";
            "EnablePackageProcessLoggingAndAssert" = "true";
        }

        It "should deploy the config file twice" {
            $result = (Get-Item $webConfigOutputFile).LastWriteTime

            $result | Should Not Be $firstWrite
        }

    }
}