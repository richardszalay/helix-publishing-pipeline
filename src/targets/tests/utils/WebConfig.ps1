function Get-WebConfigAppSetting
{
    param(
        [xml]$Xml,
        [string]$Key
    )

    return Select-Xml -Xml $Xml -XPath "//appSettings/add[@key='$Key']/@value"
}