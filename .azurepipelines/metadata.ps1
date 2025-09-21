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
    "Authorization"      = "token $env:GITHUB_TOKEN"  # 确保在环境变量中设置了 GITHUB_TOKEN
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
    $_.assets | Where-Object { $_.name -contains $assetName }
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
$tempDir = New-Item -ItemType Directory -Path (New-Guid).Guid -Force | Select-Object -ExpandProperty FullName

try {
    Write-Host "Processing and mirroring assets for the latest releases..."

    foreach ($release in $releasesToKeep) {
        $releaseId = $release.id
        
        # 针对单一 Release 遍历其所有符合条件的 Asset
        $assetsToProcess = $release.assets | Where-Object { $_.name -contains $assetName }
        $modifiedAssetsForRelease = [array]@() # 用于保存该 Release 的所有修改后 Asset
        
        Write-Host "Processing release `"$($release.tag_name)`" with $($assetsToProcess.Count) asset(s)..."

        foreach ($asset in $assetsToProcess) {
            $assetDownloadUrl = $asset.browser_download_url
            
            # 使用 Asset ID 来确保唯一性，因为文件名可能相同
            $ossObjectKey = "$ossBasePath/$releaseId/$($asset.name)"
            $localFilePath = Join-Path -Path $tempDir -ChildPath "$releaseId-$($asset.name)"

            # 增量镜像：检查 OSS 上文件是否存在
            try {
                ossutil stat oss://$ossBucketName/$ossObjectKey 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`tAsset '$($asset.name)' already exists in OSS. Skipping download."
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

            # 修改元数据中的 Asset 地址
            $modifiedAsset = @{
                browser_download_url = "$ossDownloadUrlBase/$releaseId/$($asset.name)"
                name = $asset.name
                tag_name = $release.tag_name # 方便调试
            }
            $modifiedAssetsForRelease += $modifiedAsset
        } # end foreach asset
        
        # 构造用于上传的优化元数据对象，assets 字段为数组
        $optimizedRelease = @{
            name = $release.name
            tag_name = $release.tag_name
            prerelease = $release.prerelease
            published_at = $release.published_at
            assets = @($modifiedAssetsForRelease)
        }
        $processedMetadata += $optimizedRelease
    } # end foreach release

    # ---
    ## 步骤4: 上传最新的元数据
    # ---
    $modifiedMetadataJson = @($processedMetadata) | ConvertTo-Json -Depth 10 -Compress
    $metadataFile = Join-Path -Path $tempDir -ChildPath "metadata.json"
    $modifiedMetadataJson | Out-File -Path $metadataFile -Encoding utf8

    Write-Host "Uploading metadata.json to OSS..."
    ossutil cp $metadataFile oss://$ossBucketName/$metadataKey --force
    
    # ---
    ## 步骤5: 清理 OSS 上的旧文件
    # ---
    Write-Host "Checking for old assets to clean up..."

    # 获取 OSS 上所有符合路径模式的资产列表
    $allOssAssets = ossutil ls -s oss://$ossBucketName/$ossBasePath/ 2>&1 | Select-String -Pattern "$ossBasePath/\d+/\d+/$assetName"
    
    # 构建一个需要保留的完整键（key）集合，以便快速查找
    $keysToKeep = $null
    $keysToKeep = $processedMetadata | ForEach-Object {
        $release = $_
        $release.assets | ForEach-Object {
            $asset = $_
            $key = ($asset.browser_download_url -split '.com/')[1] # 从 URL 提取 key
            $key
        }
    }

    if ($allOssAssets) {
        foreach ($ossAsset in $allOssAssets) {
            $ossAssetKey = ($ossAsset.Line -split '\s+')[2]
            
            # 如果这个资产的 Key 不在需要保留的列表中，则删除它
            if ($ossAssetKey -notin $keysToKeep) {
                Write-Host "`tDeleting old asset: $ossAssetKey"
                ossutil rm oss://$ossBucketName/$ossAssetKey
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