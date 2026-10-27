# Publish this project on GitHub

## Suggested repository identity

- **Repository name:** `recycling-first-gen-surface-book-into-a-server`
- **Title:** Recycling a First-Generation Surface Book into a Resilient Linux Server
- **Description:** Repurposing a display-damaged Surface Book 1 as a battery-backed Debian edge node, with automated installation, SSH/Docker/Tailscale, and independent mobile-uplink design.
- **Topics:** `surface-book`, `debian`, `linux`, `hardware-reuse`, `homelab`, `headless`, `ssh`, `docker`, `tailscale`, `edge-computing`, `high-availability`, `preseed`, `xorriso`, `sustainability`.

## Before publishing

1. Read `docs/SECURITY.md` and verify that only the sanitized **source** folder is being committed; never an ISO generated on your Desktop.
2. Search for hostnames, local usernames, passwords, SSIDs, hashes, Tailscale URLs, SSH secrets, device serial numbers and identifiers in images.
3. Run `bash scripts/test-static.sh`.
4. Confirm that the source and images match what you intend to release and that you hold permission to publish them.

## Easiest: GitHub web UI

1. Visit https://github.com/new and create a **public or private** repository with the name above.
2. Do **not** initialize it with a second README or license (both are already in this folder).
3. Open the repository → **Add file** → **Upload files**; drag the **contents** of this repository folder into the upload area. Preserve subfolders.
4. Commit and inspect the rendered README, images and links. Ensure `.gitignore` is present.

## Git CLI (macOS)

```bash
cd ~/Downloads/recycling-first-gen-surface-book-into-a-server
bash scripts/test-static.sh
git init -b main
git add .
git status --short
git diff --cached --stat
git commit -m "docs: repurpose Surface Book 1 as resilient Debian edge node"
```

Create a repo on GitHub via UI, then connect it (replace `YOUR_GITHUB_HANDLE`):

```bash
git remote add origin https://github.com/YOUR_GITHUB_HANDLE/recycling-first-gen-surface-book-into-a-server.git
git push -u origin main
```

Use GitHub's supported authentication flow (credential manager or personal access token), not your GitHub password pasted into scripts.

## On future commits

**Generated ISO files and logs never belong in Git history.** `.gitignore` protects common patterns but is not a security boundary. If a secret reaches Git history, deleting the file in a later commit is not enough: rotate the affected secret and clean the repository history using GitHub's current guidance.

## Make convenient downloads available

The `release.yml` workflow automatically builds macOS/Windows download ZIPs after you push a version tag. Until then **there is no live Release to download**. Follow [Release instructions](RELEASES.md). For Rufus/balenaEtcher setup use [USB flashing guide](USB_FLASHING.md).
