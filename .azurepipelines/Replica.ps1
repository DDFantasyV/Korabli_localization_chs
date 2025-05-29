#!/usr/bin/pwsh

# Ensure use PowerShell 7
#Requires -Version 7

param(
	[switch]$Test = $false
)
# GitHub API URL
$ReleaseListApi = "https://api.github.com/repos/DDFantasyV/Korabli_localization_chs/releases"

# HTTP Headers
$Headers = @{
	"Accept"		= "application/vnd.github.v3+json"
	"User-Agent"	= "PowerShell"
	"Authorization" = "Bearer $env:GITHUB_TOKEN"
	"X-GitHub-Api-Version" = "2022-11-28"
}

$assetName = "Korabli_localization_chs.zip"

$modName = "Korabli_localization_chs"
if ($isTest) {
	$modName = $modName + "_test"
}

$compressOptions = @{
	Path = "_DDFantasyV_Korabli_localization_chs/locale_config.xml", "_DDFantasyV_Korabli_localization_chs/thanks.md", "_DDFantasyV_Korabli_localization_chs/LICENSE", "_DDFantasyV_Korabli_localization_chs/change.log", "_DDFantasyV_Korabli_localization_chs/texts/"
	CompressionLevel = "Optimal"
	DestinationPath = $assetName
	Force = $true
}

Compress-Archive @compressOptions
aws s3api put-object --bucket warshipmod --key "mods/chs/$modName.zip" --body $assetName

# Aquire GitHub Release metadata
try {
	$Releases = Invoke-RestMethod -Uri $ReleaseListApi -Headers $Headers -Method Get
} catch {
	Write-Error "Unable to fetch GitHub Release data: $_"
	exit 1
}

# Modify URL to Cloudflare
$releaseMetadata = $Releases | Where-Object { $_.prerelease -eq $Test } | Sort-Object published_at -Descending | Select-Object -First 1
$releaseId = $releaseMetadata.id
$releaseAsset = $releaseMetadata.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
$uploadAssetApi = "https://uploads.github.com/repos/DDFantasyV/Korabli_localization_chs/releases/$releaseId/assets?name=$assetName"
if ($null -eq $releaseAsset) {
	$response = Invoke-WebRequest -Uri $uploadAssetApi -Headers $Headers -Method Post -InFile $assetName -ContentType "application/octet-stream"
	if ($response.StatusCode -eq 201) {
		Write-Host "Release asset uploaded successfully: $($response.BaseResponse.Headers.Location)"
	} else {
		Write-Error "Failed to upload release asset. Status code: $($response.StatusCode)"
		exit 1
	}
} else {
	Write-Host "Release asset already exists: $($releaseAsset.browser_download_url). Skipping upload."
}
