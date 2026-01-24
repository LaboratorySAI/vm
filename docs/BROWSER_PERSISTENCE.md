# 🌐 Browser Persistence Guide (Windows)

This document explains how to enable and use browser persistence for your Windows Remote Desktop sessions. This feature allows you to save and restore your Google Chrome profiles, including logged-in accounts, extensions, history, and settings, across different workflow runs.

## 🚀 How it Works

Unlike the default OpenCode persistence which uses GitHub Artifacts, Browser Persistence uses **Cloudflare R2** (S3-compatible storage). This is because browser profiles can be very large, and R2 provides a faster and more scalable way to handle this data.

### Persistence Lifecycle

1.  **Restoration**: When the workflow starts (if `enable_persistence` is selected), the `scripts/persistence-windows.ps1` script installs **Rclone** and downloads your Chrome "User Data" from your R2 bucket.
2.  **Session**: You use Chrome as normal. All changes, new tabs, and logged-in accounts are stored in the local profile.
3.  **Saving**: When the session ends (even if the workflow is cancelled or times out), the script closes Chrome and syncs the entire local "User Data" directory back to your R2 bucket.

## 🛠️ Setup Instructions

To use this feature, you must provide your own Cloudflare R2 bucket and credentials.

### 1. Create a Cloudflare R2 Bucket
- Log in to your Cloudflare dashboard.
- Go to **R2** and create a new bucket (e.g., `github-vm-persistence`).

### 2. Configure GitHub Secrets
Go to your repository **Settings > Secrets and variables > Actions** and add the following secrets:

| Secret Name | Description |
| :--- | :--- |
| `R2_ACCESS_KEY_ID` | Your R2 Access Key ID. |
| `R2_SECRET_ACCESS_KEY` | Your R2 Secret Access Key. |
| `R2_ACCOUNT_ID` | Your Cloudflare Account ID (found on the R2 overview page). |
| `R2_BUCKET` | The name of the bucket you created. |

## ⚙️ How to Enable

1. Go to the **Actions** tab in GitHub.
2. Select the **Remote Desktop Access** workflow.
3. Click **Run workflow**.
4. Check the box **Enable Browser Persistence**.
5. Click **Run workflow**.

## 📂 What is Saved?

The system syncs the entire Chrome `User Data` directory, which includes:
- **Default Profile**: Your main browsing data.
- **Multiple Profiles**: If you have created multiple Chrome profiles, all of them are saved.
- **Extensions**: All installed extensions and their settings.
- **Passwords & Cookies**: Kept local to your R2 bucket.

### Optimizations
To keep the sync fast, the following are automatically excluded:
- Browser Cache (`Cache/**`, `Code Cache/**`, `GPUCache/**`)
- System Lock files (`SingletonLock`, `lockfile`, etc.)

## 🕒 Troubleshooting

- **Sync takes too long**: Ensure you are using an R2 bucket in a region close to the GitHub runner (usually US East for `windows-latest`).
- **Data not restored**: Check the workflow logs under the "Restore Persistent Data" step for any Rclone errors.
- **Missing Secrets**: If secrets are not configured, the persistence steps will be skipped even if the checkbox is checked.

---
> [!IMPORTANT]
> This feature is currently only supported on **Windows** operating systems in the workflow.
