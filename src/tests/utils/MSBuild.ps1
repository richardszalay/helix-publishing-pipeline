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

function Get-MSBuildExePath
{
    param(
        $Version = "15.0"
    )

    return "MSBuild.exe"
}


function Invoke-MSBuild
{
    param(
        $Project,
        [hashtable]$Properties
    )

    $msBuildExe = Get-MSBuildExePath
    $propertyArgs = Format-MSBuildCommandLineProperties $Properties

    $arguments = @($propertyArgs) + @((Resolve-Path $Project)) + "/v:q" + "/nologo" + "/t:Clean;Build"

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
    #$stderr = $p.StandardError.ReadToEnd()

    if ($p.ExitCode -ne 0) {
        throw $stderr
    }

    Set-Content "tmp.txt" $stdout

    return $stdout

}

function Format-MSBuildCommandLineProperties
{
    param(
        [hashtable]$Properties
    )

    return @($Properties.GetEnumerator() | % { "/P:$($_.Key)=$($_.Value)" })
}

function ConvertTo-Dictionary
{
    param(
        [hashtable]$InputObject
    )

    $outputObject = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

    foreach ($entry in $InputObject.GetEnumerator())
    {
        $key = [string]$entry.Key
        $value = [string]$entry.Value

        $outputObject.Add($key, $value)
    }

    return $outputObject
}