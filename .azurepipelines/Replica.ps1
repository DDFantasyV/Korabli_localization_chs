param(
    [Parameter(Mandatory = $true)]
    [string] $AccessToken
)

git checkout main
git push git@gitee.com:repad/Korabli_localization_chs.git --force
git push git@gitee.com:repad/Korabli_localization_chs.git --tags

$githubReleaseApiUrl = "https://api.github.com/repos/DDFantasyV/Korabli_localization_chs/releases"
$githubReleaseHeaders = @{
	"Accept" = "application/vnd.github.v3+json"
	"X-GitHub-Api-Version" = "2022-11-28"
}

$githubResponse = Invoke-RestMethod -Uri $githubReleaseApiUrl -Headers $githubReleaseHeaders -Method Get
$latestGithubRelease = $githubResponse[0]

$giteeReleaseApiUrl = "https://gitee.com/api/v5/repos/repad/Korabli_localization_chs/releases"
$giteeReleaseHeaders = @{
	"Content-Type" = "application/json;charset=UTF-8"
}
$giteeReleaseBody = @{
	"access_token" = ${AcccessToken}
	"tag_name" = $latestGithubRelease.tag_name
	"name" = $latestGithubRelease.name
	"body" = $latestGithubRelease.body
	"prerelease" = $latestGithubRelease.prerelease
	"target_commitish" = $latestGithubRelease.target_commitish
} | ConvertTo-Json

$giteeResponse = Invoke-RestMethod -Uri $giteeReleaseApiUrl -Headers $giteeReleaseHeaders -Method Post -Body $giteeReleaseBody
$giteeResponse | Out-Null