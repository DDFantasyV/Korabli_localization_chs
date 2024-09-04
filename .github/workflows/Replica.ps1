param(
    [Parameter(Mandatory = $true)]
    [string] $AcccessToken
)

$githubReleaseApiUrl = "https://api.github.com/repos/MFunction96/KorabliChsMod/releases"
$githubReleaseHeaders = @{
	"Accept" = "application/vnd.github.v3+json"
	"X-GitHub-Api-Version" = "2022-11-28"
}

$githubResponse = Invoke-RestMethod -Uri $githubReleaseApiUrl -Headers $githubReleaseHeaders -Method Get
$latestGithubRelease = $githubResponse[0]

$giteeReleaseApiUrl = "https://gitee.com/api/v5/repos/MFunction96/KorabliChsMod/releases"
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