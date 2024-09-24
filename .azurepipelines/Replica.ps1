param(
    [Parameter(Mandatory = $true)]
    [string] $AccessToken,
	[Parameter(Mandatory = $false)]
	[string] $Branch = 'main'
)

if ([string]::IsNullOrEmpty($env:TMP)) {
	$env:TMP = '/tmp'
}

$tmpPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [guid]::NewGuid().ToString())
if ([System.IO.Directory]::Exists($tmpPath)) {
	Remove-Item -Path $tmpPath -Force -Recurse
}

[System.IO.Directory]::CreateDirectory($tmpPath)
try {
	Set-Location $tmpPath
	git clone git@github.com:DDFantasyV/Korabli_localization_chs.git --branch $Branch
	Set-Location Korabli_localization_chs
	git push git@gitee.com:repad/Korabli_localization_chs.git --force
	git push git@gitee.com:repad/Korabli_localization_chs.git --tags
	$githubReleaseApiUrl = "https://api.github.com/repos/DDFantasyV/Korabli_localization_chs/releases"
	$githubReleaseHeaders = @{
		"Accept" = "application/vnd.github.v3+json"
		"X-GitHub-Api-Version" = "2022-11-28"
	}

	$githubResponse = Invoke-RestMethod -Uri $githubReleaseApiUrl -Headers $githubReleaseHeaders -Method Get
	$latestGithubRelease = $githubResponse[0]

	$giteeReleaseTagApiUrl = "https://gitee.com/api/v5/repos/repad/Korabli_localization_chs/releases/tags/" + $latestGithubRelease.tag_name
	$giteeReleaseTagHeaders = @{
		"Content-Type" = "application/json;charset=UTF-8"
	}
	
	$giteeTagResponse = Invoke-RestMethod -Uri $giteeReleaseTagApiUrl -Headers $giteeReleaseTagHeaders -Method Get
	if ($null -eq $giteeTagResponse) {
		$giteeReleaseApiUrl = "https://gitee.com/api/v5/repos/repad/Korabli_localization_chs/releases"
		$giteeReleaseHeaders = @{
			"Content-Type" = "application/json;charset=UTF-8"
		}
		$giteeReleaseBody = @{
			"access_token" = $AccessToken
			"tag_name" = $latestGithubRelease.tag_name
			"name" = $latestGithubRelease.name
			"body" = $latestGithubRelease.body
			"prerelease" = $latestGithubRelease.prerelease
			"target_commitish" = $latestGithubRelease.target_commitish
		} | ConvertTo-Json

		$giteeResponse = Invoke-RestMethod -Uri $giteeReleaseApiUrl -Headers $giteeReleaseHeaders -Method Post -Body $giteeReleaseBody
		$giteeResponse | Out-Null
	}
	
}
catch {
	throw $_
}
finally {
	Set-Location ~
	Remove-Item -Path $tmpPath -Force -Recurse
}