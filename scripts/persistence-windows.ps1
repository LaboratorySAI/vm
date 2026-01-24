<#
.SYNOPSIS
    Handles browser data persistence using rclone and Cloudflare R2 on Windows.
#>

param (
    [Parameter(Mandatory = $true)]
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
$ChromeProfilePath = if (-not [string]::IsNullOrWhiteSpace($Username)) { "C:\Users\$Username\AppData\Local\Google\Chrome\User Data\Default" } else { $null }

function Initialize-Rclone {
    if (-not (Test-Path $RcloneExe)) {
        Write-Host "Installing rclone..."
        
        # Ensure directory exists
        if (-not (Test-Path $RcloneDir)) {
            New-Item -ItemType Directory -Force -Path $RcloneDir | Out-Null
        }
        
        $zipPath = "$env:TEMP\rclone.zip"
        $tempExtractPath = "$env:TEMP\rclone-temp"
        
        # Clean up any previous temp files
        if (Test-Path $tempExtractPath) {
            Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "Downloading rclone..."
        Invoke-WebRequest -Uri "https://downloads.rclone.org/rclone-current-windows-amd64.zip" -OutFile $zipPath -UseBasicParsing
        
        if (-not (Test-Path $zipPath)) {
            throw "Failed to download rclone archive"
        }
        
        Write-Host "Extracting rclone..."
        Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
        
        # Find rclone.exe with explicit null handling
        $tempExeList = @(Get-ChildItem -Path $tempExtractPath -Filter "rclone.exe" -Recurse -ErrorAction SilentlyContinue)
        
        if ($null -eq $tempExeList -or $tempExeList.Count -eq 0) {
            # List contents for debugging
            Write-Host "Contents of extract directory:"
            Get-ChildItem -Path $tempExtractPath -Recurse | ForEach-Object { Write-Host $_.FullName }
            throw "Failed to find rclone.exe in downloaded archive"
        }
        
        $tempExe = $tempExeList[0]
        $tempExeFullName = $tempExe.FullName
        
        if ([string]::IsNullOrWhiteSpace($tempExeFullName)) {
            throw "rclone.exe path is null or empty"
        }
        
        Write-Host "Moving rclone.exe from $tempExeFullName to $RcloneExe"
        Move-Item -Path $tempExeFullName -Destination $RcloneExe -Force
        
        # Cleanup
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "rclone installation complete."
    }

    # Validate parameters before creating config
    if ([string]::IsNullOrWhiteSpace($R2AccessTokenId) -or 
        [string]::IsNullOrWhiteSpace($R2SecretAccessKey) -or 
        [string]::IsNullOrWhiteSpace($R2AccountId)) {
        throw "R2 credentials are not properly set"
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
    try {
        $chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
        if ($chromeProcesses) {
            Write-Host "Closing Chrome processes..."
            $chromeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }
    }
    catch {
        Write-Warning "Note: Issue while stopping Chrome: $_"
    }

    if ($null -eq $ChromeProfilePath -or [string]::IsNullOrWhiteSpace($ChromeProfilePath)) {
        Write-Warning "Chrome profile path is not set. Skipping save."
        return
    }

    # Check if the Chrome profile exists
    if (-not (Test-Path $ChromeProfilePath)) {
        Write-Host "Chrome profile not found at $ChromeProfilePath. Nothing to save."
        # List User Data directory to find actual profile names
        $userDataPath = Split-Path $ChromeProfilePath -Parent
        if (Test-Path $userDataPath) {
            Write-Host "Contents of Chrome User Data ($userDataPath):"
            Get-ChildItem -Path $userDataPath -Directory | ForEach-Object { Write-Host " - Profile folder: $($_.Name)" }
        }
        return
    }

    # Debug: List profile contents
    Write-Host "Listing contents of $ChromeProfilePath (top level):"
    Get-ChildItem -Path $ChromeProfilePath -Force | ForEach-Object { Write-Host " - $($_.Name)" }
    
    if (-not (Test-Path $RcloneExe)) {
        Write-Warning "rclone executable not found at $RcloneExe. Skipping save."
        return
    }

    # Sync from local to R2, excluding lock files and cache
    try {
        & $RcloneExe sync "$ChromeProfilePath" "r2:$R2Bucket/profiles/$Username/Chrome" `
            --config $ConfigPath `
            --verbose `
            --links `
            --exclude "Lock" `
            --exclude "SingletonLock" `
            --exclude "*.lock" `
            --exclude "**/Cache/**" `
            --exclude "**/Code Cache/**" `
            --exclude "**/GPUCache/**" `
            --ignore-errors
        Write-Host "Save complete."
    }
    catch {
        throw "Rclone sync failed: $_"
    }
}

# Execution
try {
    # Validate parameters before proceeding
    if (-not (Test-RequiredParams)) {
        Write-Host "Persistence action skipped due to missing parameters."
        exit 0
    }
    
    Initialize-Rclone
    if ($Action -eq "restore") {
        Restore-BrowserData
    }
    elseif ($Action -eq "save") {
        Save-BrowserData
    }
}
catch {
    $errorMessage = $_.Exception.Message
    if ($null -eq $errorMessage) { $errorMessage = $_.ToString() }
    Write-Error "Persistence action failed: $errorMessage"
    Write-Debug "Stack Trace: $($_.ScriptStackTrace)"
    exit 1
}
finally {
    if ((Test-Path variable:ConfigPath) -and $ConfigPath -and (Test-Path $ConfigPath)) {
        Remove-Item -Path $ConfigPath -Force -ErrorAction SilentlyContinue
    }
}
