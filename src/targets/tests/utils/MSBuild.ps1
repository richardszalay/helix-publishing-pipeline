#Add-Type -AssemblyName 'Microsoft.Build, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'

function Get-MSBuildToolsPath
{
    param(
        $Version = "14.0"
    )

    return (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$Version").MSBuildToolsPath32
}

function Add-MSBuildAssembly
{
    param(
        $Version = "14.0"
    )

    $assembly = Join-Path (Get-MSBuildToolsPath $Version) "Microsoft.Build.dll"

    Add-Type -Path $assembly
}

function Get-VSWherePath
{
    $localPath = "$PSScriptRoot\tools\vswhere.exe"

    if (-not (Test-Path $localPath))
    {
        mkdir (Split-Path $localPath -Parent) -ErrorAction SilentlyContinue | Out-Null

        Invoke-WebRequest -OutFile $localPath -Uri "https://github.com/Microsoft/vswhere/releases/download/2.2.3/vswhere.exe" | Out-Null
    }

    return $localPath
}

function Get-MSBuildExePath
{
    param(
        $Version = "15.0"
    )

    $path = & (Get-VSWherePath) -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
    if ($path) {
      $path = join-path $path 'MSBuild\15.0\Bin\MSBuild.exe'
      if (test-path $path) {
        return $path
      }
    }

    return "MSBuild.exe"
}

function Invoke-MSBuildWithOutput
{
    param(
        $Project,
        [hashtable]$Properties,
        [string]$TargetName,
        [Parameter(ParameterSetName='ItemOutput')]$OutputItem
    )

    $projectFile = (Resolve-Path $Project)
    $outputDataFile = (New-TemporaryFile).FullName
    
    if ($OutputItem) {
        $projectFile = New-MSBuildTargetsWrapper -TargetsFile $projectFile -TargetName $TargetName -OutputItem $OutputItem -OutputBuffer $outputDataFile
    }

    Invoke-MSBuild $projectFile -TargetName "Test$TargetName" -Properties $Properties + @{"IsWrapperInstance"="true"} | Out-Null

    return @(Get-Content $outputDataFile)
}

function Invoke-MSBuild
{
    param(
        $Project,
        [hashtable]$Properties,
        $TargetName = "Clean;Build"
    )

    $msBuildExe = Get-MSBuildExePath
    $propertyArgs = Format-MSBuildCommandLineProperties $Properties

    $arguments = @($propertyArgs) + (Resolve-Path $Project) + "/v:q" + "/nologo" + "/t:$TargetName"

    Write-Verbose "Invoking MSBuild: $msBuildExe $arguments"

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $msBuildExe
    $pinfo.RedirectStandardError = $true
    #$pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    #$stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()

    if ($p.ExitCode -ne 0) {
        throw $stderr
    }

    return $stdout

}

function Format-MSBuildCommandLineProperties
{
    param(
        [hashtable]$Properties
    )

    if (-not $Properties) {
        return @()
    }

    return @($Properties.GetEnumerator() | % { "/P:$($_.Key)=$($_.Value)" })
}

function New-MSBuildTargetsWrapper
{
    param(
        $TargetsFile,
        $TargetName,
        $OutputItem,
        $OutputBuffer
    )

    $targetsDir = Split-Path -Path $TargetsFile -Parent
    $targetsFilename = Split-Path -Path $TargetsFile -Leaf

    $tempFile = Join-Path $targetsDir ([System.IO.Path]::ChangeExtension($targetsFilename, ".test.targets"))

    $returnsValue = "@($OutputItem)"

    Set-Content $tempFile "
        <Project>
            <Import Project=`"$TargetsFile`" />

            <Target Name=`"Test$TargetName`" DependsOnTargets=`"$TargetName`">
                <ItemGroup>
                    <_TestOutputLines Include=`"$returnsValue`" />
                </ItemGroup>

                <WriteLinesToFile File=`"$OutputBuffer`" Lines=`"@(_TestOutputLines)`" Overwrite=`"true`" />
            </Target>
        </Project>
    "

    return $tempFile
}
