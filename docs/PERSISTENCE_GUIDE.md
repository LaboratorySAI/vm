# 💾 OpenChamber & OpenCode Persistence Guide

This document explains how session data, configurations, and chat history are persisted across GitHub Action runs for the OpenChamber/OpenCode environment.

## 🔍 How it Works

Unlike standard temporary VMs, this environment uses a robust persistence layer based on **GitHub Actions Artifacts**. This allows you to pick up exactly where you left off in your chats and coding tasks.

### Persistence Lifecycle

1.  **Restoration**: When the workflow starts, it attempts to download the most recent artifact named `opencode-session`.
2.  **Application**: The `scripts/persistence-restore.sh` script applies the restored data to your home directory (`~/.config/opencode` and `~/.local/share/opencode`).
3.  **Configuration**: The `scripts/opencode-config.sh` script checks if a restored configuration exists. If it finds one (even if it's a `.yml` file), it uses it. If not, it generates a default `opencode.json`.
4.  **Monitoring**: The `scripts/monitor.sh` script ensures services stay alive and handles the background execution.
5.  **Saving**: When the workflow finishes (or is cancelled), the `scripts/persistence-save.sh` script gathers all critical data, creates a manifest, and prepares it for upload.

## 📂 What is Saved?

We save everything necessary for a seamless experience while excluding bulky temporary files:

| Category | Location | Saved Items |
| :--- | :--- | :--- |
| **Configuration** | `~/.config/opencode/` | All settings, account info, and model configs. |
| **Auth** | `~/.local/share/opencode/` | `auth.json` (OAuth tokens and login state). |
| **Storage** | `~/.local/share/opencode/storage/` | All chat history, messages, message parts, and session metadata. |
| **Snapshots** | `~/.local/share/opencode/snapshot/` | Project snapshots and history for undo/rollback. |
| **Logs** | `~/.local/share/opencode/log/` | Service logs for debugging. |

### Excluded Items
To keep artifacts small and fast:
- `node_modules/` (Reinstalled on each run)
- `bin/` (CLI tools reinstalled on each run)
- `tool-output/` (Temporary outputs)

## 🛠 Script Architecture

The persistence logic has been modularized into specialized scripts for better maintainability:

-   `scripts/opencode-config.sh`: Intelligent config management. Implements "Restored Config Wins" policy.
-   `scripts/persistence-restore.sh`: Handles the extraction and placement of restored data.
-   `scripts/persistence-save.sh`: Efficiently gathers data and creates a `manifest.json` metadata file.
-   `scripts/monitor.sh`: A self-healing loop that monitors services and manages the tunnel.

## ⚙️ Configuration Preference

The system follows this priority when setting up OpenCode:
1.  **Restored Artifact**: If `opencode.yml`, `opencode.yaml`, or `opencode.json` exists in the restored data, it is used immediately.
2.  **Existing File**: If a file already exists in the config directory from a manual setup step.
3.  **Default Template**: Generates the standard Antigravity Suite configuration.

## 🕒 Retention Policy

-   **Artifact Retention**: Saved for **90 days** (the maximum allowed by GitHub).
-   **Old Versions**: Each successful run overwrites the `opencode-session` artifact with the latest state.
