#!/usr/bin/pwsh

# Ensure use PowerShell 7
#Requires -Version 7

# GitHub API URL
$GitHubApiUrl = "https://api.github.com/repos/DDFantasyV/Korabli_localization_chs/releases"

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
$LatestRelease.zipball_url = "https://warshipmod.mfbrain.xyz/mods/chs/Korabli_localization_chs.zip"
$LatestPreRelease.zipball_url = "https://warshipmod.mfbrain.xyz/mods/chs/Korabli_localization_chs_test.zip"
$FilteredReleases = @()
if ($LatestRelease) { $FilteredReleases += $LatestRelease }
if ($LatestPreRelease) { $FilteredReleases += $LatestPreRelease }

$OptimizedMetadata = @($FilteredReleases | ForEach-Object {
	@{
		name		  = $_.name
		prerelease	= $_.prerelease
		published_at  = $_.published_at
		zipball_url   = $_.zipball_url
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
