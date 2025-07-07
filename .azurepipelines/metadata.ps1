#!/usr/bin/pwsh

# Ensure use PowerShell 7
#Requires -Version 7

# GitHub API URL
$GitHubApiUrl = "https://api.github.com/repos/DDFantasyV/Korabli_localization_chs/releases"
$assetName = "Korabli_localization_chs.zip"

# HTTP Headers
$Headers = @{
	"Accept"		= "application/vnd.github.v3+json"
	"User-Agent"	= "PowerShell"
	"X-GitHub-Api-Version" = "2022-11-28"
}

# Aquire GitHub Release metadata
try {
	$Releases = Invoke-RestMethod -Uri $GitHubApiUrl -Headers $Headers -Method Get
} catch {
	Write-Error "Unable to fetch GitHub Release data: $_"
	exit 1
}

# Modify URL to Cloudflare
$LatestRelease = $Releases | Where-Object { -not $_.prerelease } | Sort-Object published_at -Descending | Select-Object -First 1
$LatestPreRelease = $Releases | Where-Object { $_.prerelease } | Sort-Object published_at -Descending | Select-Object -First 1
$LatestRelease.assets = [array]@(@{
	browser_download_url = "https://warshipmod.mfbrain.xyz/mods/chs/Korabli_localization_chs.zip"
	tag_name = $LatestRelease.tag_name
	name = $assetName
})
$LatestPreRelease.assets = [array]@(@{
	browser_download_url = "https://warshipmod.mfbrain.xyz/mods/chs/Korabli_localization_chs_test.zip"
	tag_name = $LatestPreRelease.tag_name
	name = $assetName
})

$FilteredReleases = @()
if ($LatestRelease) { $FilteredReleases += $LatestRelease }
if ($LatestPreRelease) { $FilteredReleases += $LatestPreRelease }

$OptimizedMetadata = @($FilteredReleases | ForEach-Object {
	@{
		name		  = $_.name
		tag_name	  = $_.tag_name
		prerelease	= $_.prerelease
		published_at  = $_.published_at
		assets   = [array]@($_.assets | ForEach-Object {
			@{
				browser_download_url  = $_.browser_download_url
				name = $_.name
			}
		})
	}
})

# Convert modified metadata to JSON
$ModifiedMetadata = ConvertTo-Json -Depth 10 -Compress $OptimizedMetadata

# Generate temporary file
$MetadataFile = New-TemporaryFile
$ModifiedMetadata | Set-Content -Path $MetadataFile.FullName -Encoding UTF8

# Upload to Cloudflare R2
try {
	aws s3api put-object --bucket warshipmod --key "mods/chs/metadata.json" --body $MetadataFile
} catch {
	Write-Error $_
	exit 1
} finally {
	Remove-Item -Path $MetadataFile.FullName -Force
}

exit 0
