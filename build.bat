@ECHO OFF

IF [%1] == [] (
    SET PACKAGE_VERSION=0.0.0
) else (
    SET PACKAGE_VERSION=%1
)

powershell -command "& { Import-Module '%~dp0\build\psake\psake.psd1'; Invoke-psake '%~dp0\build\default.ps1' -taskList Test,Pack -parameters @{packageVersion='%PACKAGE_VERSION%'} }"