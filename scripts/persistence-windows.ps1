<#
.SYNOPSIS
    Handles browser data persistence using rclone and Cloudflare R2 on Windows.
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("restore", "save")]
    [string]$Action,

    [string]$R2AccessTokenId,
    [string]$R2SecretAccessKey,
    [string]$R2AccountId,
    [string]$R2Bucket,
    [string]$Username
)

# Validate required parameters for R2 operations
function Test-RequiredParams {
    $missingParams = @()
    if ([string]::IsNullOrWhiteSpace($R2AccessTokenId)) { $missingParams += "R2AccessTokenId" }
    if ([string]::IsNullOrWhiteSpace($R2SecretAccessKey)) { $missingParams += "R2SecretAccessKey" }
    if ([string]::IsNullOrWhiteSpace($R2AccountId)) { $missingParams += "R2AccountId" }
    if ([string]::IsNullOrWhiteSpace($R2Bucket)) { $missingParams += "R2Bucket" }
    if ([string]::IsNullOrWhiteSpace($Username)) { $missingParams += "Username" }
    
    if ($missingParams.Count -gt 0) {
        Write-Warning "Missing required parameters: $($missingParams -join ', '). Skipping persistence action."
        return $false
    }
    return $true
}

$RcloneDir = "$env:ProgramFiles\rclone"
$RcloneExe = "$RcloneDir\rclone.exe"
$ConfigPath = "$env:TEMP\rclone.conf"
$ChromeProfilePath = if (-not [string]::IsNullOrWhiteSpace($Username)) { "C:\Users\$Username\AppData\Local\Google\Chrome\User Data" } else { $null }

function Setup-Rclone {
    if (-not (Test-Path $RcloneExe)) {
        Write-Host "Installing rclone..."
        New-Item -ItemType Directory -Force -Path $RcloneDir | Out-Null
        $zipPath = "$env:TEMP\rclone.zip"
        Invoke-WebRequest -Uri "https://downloads.rclone.org/rclone-current-windows-amd64.zip" -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath "$env:TEMP\rclone-temp" -Force
        $tempExe = Get-ChildItem -Path "$env:TEMP\rclone-temp" -Filter "rclone.exe" -Recurse | Select-Object -First 1
        if ($null -eq $tempExe) {
            throw "Failed to find rclone.exe in downloaded archive"
        }
        Move-Item -Path $tempExe.FullName -Destination $RcloneExe -Force
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:TEMP\rclone-temp" -Recurse -Force -ErrorAction SilentlyContinue
    }

    $configContent = @"
[r2]
type = s3
provider = Cloudflare
access_key_id = $R2AccessTokenId
secret_access_key = $R2SecretAccessKey
endpoint = https://$R2AccountId.r2.cloudflarestorage.com
acl = private
"@
    $configContent | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
}

function Restore-BrowserData {
    Write-Host "Restoring browser data from R2..."
    
    if ([string]::IsNullOrWhiteSpace($ChromeProfilePath)) {
        Write-Warning "Chrome profile path is not set. Skipping restore."
        return
    }
    
    if (-not (Test-Path $ChromeProfilePath)) {
        New-Item -ItemType Directory -Force -Path $ChromeProfilePath | Out-Null
    }
    
    if (-not (Test-Path $RcloneExe)) {
        Write-Warning "rclone executable not found at $RcloneExe. Skipping restore."
        return
    }
    
    # Sync from R2 to local, excluding lock files
    & $RcloneExe sync "r2:$R2Bucket/profiles/$Username/Chrome" "$ChromeProfilePath" `
        --config $ConfigPath `
        --progress `
        --links `
        --ignore-errors
    Write-Host "Restore complete."
}

function Save-BrowserData {
    Write-Host "Saving browser data to R2..."
    
    # Close Chrome if it's running
    Stop-Process -Name "chrome" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    if ([string]::IsNullOrWhiteSpace($ChromeProfilePath)) {
        Write-Warning "Chrome profile path is not set. Skipping save."
        return
    }

    # Check if the Chrome profile exists
    if (-not (Test-Path $ChromeProfilePath)) {
        Write-Host "Chrome profile not found at $ChromeProfilePath. Nothing to save."
        return
    }
    
    if (-not (Test-Path $RcloneExe)) {
        Write-Warning "rclone executable not found at $RcloneExe. Skipping save."
        return
    }

    # Sync from local to R2, excluding lock files and cache
    & $RcloneExe sync "$ChromeProfilePath" "r2:$R2Bucket/profiles/$Username/Chrome" `
        --config $ConfigPath `
        --progress `
        --links `
        --exclude "lockfile" `
        --exclude "SingletonLock" `
        --exclude "*.lock" `
        --exclude "Cache/**" `
        --exclude "Code Cache/**" `
        --exclude "GPUCache/**" `
        --ignore-errors
    Write-Host "Save complete."
}

# Execution
try {
    # Validate parameters before proceeding
    if (-not (Test-RequiredParams)) {
        Write-Host "Persistence action skipped due to missing parameters."
        exit 0
    }
    
    Setup-Rclone
    if ($Action -eq "restore") {
        Restore-BrowserData
    } elseif ($Action -eq "save") {
        Save-BrowserData
    }
} catch {
    Write-Error "Persistence action failed: $_"
    exit 1
} finally {
    if ((Test-Path variable:ConfigPath) -and $ConfigPath -and (Test-Path $ConfigPath)) {
        Remove-Item -Path $ConfigPath -Force -ErrorAction SilentlyContinue
    }
}
