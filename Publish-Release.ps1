param(
    [string]$PackageVersion,
    [string]$NugetApiKey
)

Import-Module .\build\Psake\Psake.psd1

Invoke-psake .\build\default.ps1 -parameters @{packageVersion=$PackageVersion}