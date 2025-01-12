param(
	[switch]$isTest = $false
)

$modName = "Korabli_localization_chs"
if ($isTest) {
	$modName = $modName + "_test"
}

Compress-Archive -Path _DDFantasyV_Korabli_localization_chs -DestinationPath Korabli_localization_chs.zip -CompressionLevel Optimal -Force
aws s3api put-object --bucket warshipmod --key "mods/chs/$modName.zip" --body Korabli_localization_chs.zip