#!/usr/bin/pwsh

# Ensure use PowerShell 7
#Requires -Version 7

# 参数配置
$GitHubApiUrl = "https://api.github.com/repos/DDFantasyV/Korabli_localization_chs/releases"
$assetName = "MK_L10N_CHS.mkmod"
$ossBucketName = "mk-localization-chs"
$ossEndpoint = "oss-cn-wulanchabu.aliyuncs.com"
$ossBasePath = "mods/chs"
$ossDownloadUrlBase = "https://$ossBucketName.$ossEndpoint/$ossBasePath"
$metadataKey = "$ossBasePath/metadata.json"

# HTTP Headers
$Headers = @{
    "Accept"             = "application/vnd.github.v3+json"
    "User-Agent"         = "PowerShell"
    "X-GitHub-Api-Version" = "2022-11-28"
}

# ---
## 步骤1 & 2: 抓取并筛选最新的 Release/Prerelease
# ---
Write-Host "Fetching GitHub releases from: $GitHubApiUrl"

try {
    # Fetch all releases
    $allReleases = Invoke-RestMethod -Uri $GitHubApiUrl -Headers $Headers -Method Get
} catch {
    Write-Error "Unable to fetch GitHub Release data: $_"
    exit 1
}

Write-Host "Filtering releases for asset '$assetName' and keeping only the latest..."

$allFilteredReleases = $allReleases | Where-Object {
    $_.assets | Where-Object { $_.name -eq $assetName }
}

if (-not $allFilteredReleases) {
    Write-Warning "No releases with asset '$assetName' found. Exiting."
    exit 0
}

# 筛选出最新的两个非预发布版 (Release) 和两个预发布版 (Prerelease)
$latestReleases = $allFilteredReleases | Where-Object { -not $_.prerelease } | Sort-Object published_at -Descending | Select-Object -First 2
$latestPrereleases = $allFilteredReleases | Where-Object { $_.prerelease } | Sort-Object published_at -Descending | Select-Object -First 2

$releasesToKeep = @($latestReleases) + @($latestPrereleases) | Sort-Object published_at -Descending

if (-not $releasesToKeep) {
    Write-Warning "No valid releases found after filtering. Exiting."
    exit 0
}

# ---
## 步骤3: 处理并镜像最新的资产
# ---
$processedMetadata = [array]@()
$releasesToKeepIds = $releasesToKeep.id
$tempDir = New-Item -ItemType Directory -Path (New-Guid).Guid -Force | Select-Object -ExpandProperty FullName

try {
    Write-Host "Processing and mirroring assets for the latest releases..."

    foreach ($release in $releasesToKeep) {
        $releaseId = $release.id
        $asset = $release.assets | Where-Object { $_.name -eq $assetName }
        $assetDownloadUrl = $asset.browser_download_url
        $ossObjectKey = "$ossBasePath/$releaseId/$assetName"
        $localFilePath = Join-Path -Path $tempDir -ChildPath "$releaseId-$assetName"

        Write-Host "Processing release `"$($release.tag_name)`"..."

        # 增量镜像：检查 OSS 上文件是否存在
        try {
            ossutil stat oss://$ossBucketName/$ossObjectKey 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`tAsset '$assetName' already exists in OSS. Skipping download."
            } else {
                Write-Host "`tAsset not found in OSS. Downloading from GitHub..."
                Invoke-WebRequest -Uri $assetDownloadUrl -OutFile $localFilePath -Headers $Headers

                Write-Host "`tUploading to OSS at oss://$ossBucketName/$ossObjectKey..."
                ossutil cp $localFilePath oss://$ossBucketName/$ossObjectKey
                
                Remove-Item $localFilePath -Force
            }
        } catch {
            Write-Error "`tAn error occurred during asset mirroring: $_"
        }

        # 修改元数据中的 Asset 地址并构建新的 metadata
        $modifiedAsset = @{
            browser_download_url = "$ossDownloadUrlBase/$releaseId/$assetName"
            name = $asset.name
            tag_name = $release.tag_name
        }
        
        $optimizedRelease = @{
            name = $release.name
            tag_name = $release.tag_name
            prerelease = $release.prerelease
            published_at = $release.published_at
            assets = [array]@($modifiedAsset)
        }
        $processedMetadata += $optimizedRelease
    }

    # ---
    ## 步骤4: 上传最新的元数据
    # ---
    $modifiedMetadataJson = ConvertTo-Json -Depth 10 -Compress @($processedMetadata)
    $metadataFile = Join-Path -Path $tempDir -ChildPath "metadata.json"
    $modifiedMetadataJson | Out-File -Path $metadataFile -Encoding utf8

    Write-Host "Uploading metadata.json to OSS..."
    ossutil cp $metadataFile oss://$ossBucketName/$metadataKey --force
    
    # ---
    ## 步骤5: 清理 OSS 上的旧文件
    # ---
    Write-Host "Checking for old assets to clean up..."

    # 获取 OSS 上所有符合路径模式的资产列表
    $allOssAssets = ossutil ls -s oss://$ossBucketName/$ossBasePath/ 2>&1 | Select-String -Pattern "$ossBasePath/\d+/$assetName"
    
    if ($allOssAssets) {
        foreach ($ossAsset in $allOssAssets) {
            # 从 ossutil ls 的输出中提取 key
            $ossAssetKey = ($ossAsset.Line -split '\s+')[2]
            $ossAssetId = ($ossAssetKey -split '/')[2]

            # 如果这个资产的 ID 不在需要保留的列表中，则删除它
            if ($ossAssetId -notin $releasesToKeepIds) {
                Write-Host "`tDeleting old asset: $ossAssetKey"
                ossutil rm oss://$ossBucketName/$ossAssetKey --force
            }
        }
    }
    
    Write-Host "Script finished successfully."

} catch {
    Write-Error "A fatal error occurred: $_"
    exit 1
} finally {
    if (Test-Path $tempDir) {
        Write-Host "Cleaning up temporary directory..."
        Remove-Item -Path $tempDir -Recurse -Force
    }
}