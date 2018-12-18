function Get-SitecoreSetting
{
    param(
        [xml]$Xml,
        [string]$Key
    )

    return Select-Xml -Xml $Xml -XPath "//sitecore/settings/setting[@name='$Key']/@value"
}