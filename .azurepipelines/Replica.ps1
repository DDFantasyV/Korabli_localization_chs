param(
	[switch]$isTest = $false
)

$modName = "Korabli_localization_chs"
if ($isTest) {
	$modName = $modName + "_test"
}

$compressOptions = @{
	Path = "_DDFantasyV_Korabli_localization_chs/locale_config.xml", "_DDFantasyV_Korabli_localization_chs/thanks.md", "_DDFantasyV_Korabli_localization_chs/LICENSE", "_DDFantasyV_Korabli_localization_chs/change.log", "_DDFantasyV_Korabli_localization_chs/texts/"
	CompressionLevel = "Optimal"
	DestinationPath = "Korabli_localization_chs.zip"
	Force = $true
}

Compress-Archive @compressOptions
aws s3api put-object --bucket warshipmod --key "mods/chs/$modName.zip" --body Korabli_localization_chs.zip