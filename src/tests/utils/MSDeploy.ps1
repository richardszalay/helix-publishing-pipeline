

function Invoke-MsDeploy([string[]]$arguments)
{
    $MsDeployExePath = Get-MSDeployExePath

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $MsDeployExePath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()

    if ($p.ExitCode -ne 0) {
        throw $stderr
    }

    return $stdout
}

function Get-MSDeployPackageFiles
{
    param(
        $Path
    )

    # Must be absolute
    $Path = Resolve-Path $Path
    
    $fileList = (Invoke-MsDeploy @(
        "-verb:dump",
        "-source:package=$Path"
    )).Split([Environment].NewLine)

    $fileListWithoutContainer = $fileList | Select-Object -Skip 2

    $prefix = $fileListWithoutContainer[0]

    return $fileListWithoutContainer | 
        Where-Object { $_.StartsWith($prefix + "\") } | 
        Foreach-Object { $_.Substring($prefix.Length + 1) }
}

function Get-MSDeployPackageContentPathPrefix
{
    param(
        $Path
    )

    # Must be absolute
    $Path = Resolve-Path $Path
    
    $manifest = [xml](Invoke-MsDeploy @(
        "-verb:dump",
        "-source:package=$Path",
        "-xml"
    ))

    return $manifest.output.sitemanifest.contentPath.path
}

function Get-MSDeployPackageFileContent
{
    param(
        $PackagePath,
        $FilePath
    )

    # Must be absolute
    $PackagePath = Resolve-Path $PackagePath

    $prefix = Get-MSDeployPackageContentPathPrefix $PackagePath
    $prefixAsRegex = [Regex]::Escape($prefix)

    $tempDir = GetTempDir
    
    Invoke-MsDeploy @(
        "-verb:sync",
        "-source:package=$PackagePath",
        "-dest:auto",
        "-setParam:kind=ProviderPath,scope=contentPath,match=$prefixAsRegex,value=$tempDir"
    ) | Out-Null

    $tempFile = Join-Path $tempDir $FilePath

    return Get-Content $tempFile -Raw
}

function GetTempDir()
{
    $tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())

    [System.IO.Directory]::CreateDirectory($tempDirectory) | Out-Null

    return $tempDirectory    
}

function Get-MSDeployPackageParameters
{
    param(
        $Path
    )

    # Must be absolute
    $Path = Resolve-Path $Path

    $parametersXml = Invoke-MsDeploy @(
        "-verb:getParameters",
        "-source:package=$Path"
    )

    return ConvertFrom-MSDeployParametersXML ([xml]$parametersXml)
}

function ConvertFrom-MSDeployParametersXML
{
    param(
        $Xml
    )

    #Write-Host ([xml]$Xml).GetType()

    $parameters = $Xml.output.parameters.parameter

    Write-Host $Xml

    $keyedParameters = @{}
    $parameters | ForEach-Object {
        $keyedParameters[$_.name] = $_
    }
    return $keyedParameters
}

function Get-MSDeployExePath
{
    [CmdletBinding()]
    param()

    if ($ENV:MSDeployPath) {
        return $ENV:MSDeployPath
    }

    $msDeployInstallPath = (get-childitem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | 
        Select -last 1
    ).GetValue("InstallPath")

    if ($msDeployInstallPath) {
        return "$($msDeployInstallPath)msdeploy.exe"
    }

    Throw "Unable to determine MSDeploy Path"
}