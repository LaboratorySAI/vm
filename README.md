<div align="center">
  <img src="https://i.postimg.cc/SxLbYS2C/20250929-143416.png" width="120" height="120" style="border-radius:50%; box-shadow: 0 4px 15px rgba(0,0,0,0.3);">

# ⚡ Antigravity VM Suite ⚡
**High-Performance, Persistent Virtual Machines on GitHub Actions**

[![GitHub Stars](https://img.shields.io/github/stars/TheRealAshik/VM?style=for-the-badge&color=ffd700)](https://github.com/TheRealAshik/VM/stargazers)
[![License](https://img.shields.io/github/license/TheRealAshik/VM?style=for-the-badge&color=007bff)](LICENSE)
[![GitHub Workflows](https://img.shields.io/github/actions/workflow/status/TheRealAshik/VM/remotedesktop.yml?label=RDP%20Status&style=for-the-badge)](https://github.com/TheRealAshik/VM/actions)

---

**Antigravity VM Suite** transforms GitHub Actions into a powerful workspace provider. Get a temporary, remote desktop environment for Windows, macOS, or Ubuntu in just 2 minutes—perfect for heavy development, testing, or bypass tasks.

[🚀 **Deploy Now**](#-quick-start) • [📖 **Docs**](#-documentation) • [🛠️ **Features**](#-key-features)

</div>

---

## ✨ Key Features

| 💻 OS Support | 🔒 Connectivity | 💾 Persistence |
| :--- | :--- | :--- |
| **Windows** (Latest/11-ARM) | **RDP** (Remote Desktop) | **R2 Storage** (Browser Profiles) |
| **macOS** (Latest) | **VNC** (Screen Sharing) | **GitHub Artifacts** (Env State) |
| **Ubuntu** (Latest) | **SSH** (Secure Shell) | **Session Restore** (Auto-pick up) |

- **Dual Tunneling**: Support for both `ngrok` and `cloudflared` for rock-solid stability.
- **Audio Support**: Virtual sound card integration for Windows RDP.
- **One-Click Setup**: Pre-install VS Code, Android Studio, GitHub Desktop, and more.
- **Multi-Profile Sync**: Persistent Chrome profiles including accounts and extensions.

---

## 🚀 Quick Start

1. **Fork this Repository**: Create your private environment instance.
2. **Configure Secrets**: Go to `Settings > Secrets > Actions` and add:
   - `USER_PASSWORD`: Your VM login password.
   - `NGROK_AUTH_TOKEN`: (Optional) For ngrok tunnels.
   - `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, etc. (Optional, for Browser Persistence).
3. **Trigger Workflow**:
   - Go to the **Actions** tab.
   - Select **Remote Desktop Access**.
   - Click **Run workflow** & choose your OS.
4. **Connect**: Find the connection address in the **Display Connection Details** step of the runner logs.

---

## 💾 Persistence Overview

We provide two distinct ways to keep your work safe:

### 1. Browser Persistence (Cloudflare R2)
*New!* Specifically designed for high-performance syncing of Google Chrome profiles.
- Syncs bookmarks, passwords, and **all logged-in Google accounts**.
- Excludes bulky cache to keep startup/shutdown fast.
- [Read the Browser Persistence Guide →](docs/BROWSER_PERSISTENCE.md)

### 2. OpenCode Session Persistence (Artifacts)
Classic persistence for environment variables, chat history, and local coding configurations.
- Saves to GitHub Artifacts (90-day retention).
- Restores automatically on every run.
- [Read the Persistence Technical Guide →](docs/PERSISTENCE_GUIDE.md)

---

## 🖥️ Documentation Portal

Explore our detailed guides to master your environment:

- **[Installation Guide](docs/INSTALLATION_AND_USE.md)**: Recommended clients for RDP and VNC.
- **[Configuration Matrix](docs/CONFIGURATIONS.md)**: Every toggle, input, and secret explained.
- **[VM Specifications](docs/VM_INFO.md)**: CPU, RAM, and Storage breakdown for each runner.
- **[Software Catalog](docs/PRE_INSTALLED_SOFTWARE.md)**: List of all optional software you can auto-install.
- **[SSH & Termius](docs/SSH_TERMIUS_GUIDE.md)**: Setting up secure terminal-only access.
- **[Technical Breakdown](docs/HOW_IT_WORKS.md)**: How we use Rclone, Ngrok, and PowerShell to automate the cloud.

---

<div align="center">

### ⚠️ Disclaimer
*This project is for educational and development purposes. Please adhere to the [GitHub Actions Terms of Service](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service). The macOS and Ubuntu workflows are community-maintained.*

[docs/DISCLAIMER.md](docs/DISCLAIMER.md)

</div>
