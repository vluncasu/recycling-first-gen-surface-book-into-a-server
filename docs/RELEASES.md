# GitHub Releases: distribute the installers, not the credentials

The repository contains a complete **release pipeline** but no public release is created merely by downloading or uploading this source ZIP. GitHub releases become available after you publish the repository and push a version tag.

## What users should download

- `SurfaceBook-Installer-macOS-<version>.zip` — macOS `.command` builder, source templates, docs and optional SSH post-configurer.
- `SurfaceBook-Installer-Windows-<version>.zip` — `.cmd`/PowerShell front end, Linux build engine for WSL, docs and optional remote post-configurer.
- `SHA256SUMS.txt` — checksums of the two release bundles.
- GitHub automatically provides source archives for each tagged release.

**Do not upload** generated `.iso`, `.img`, network profiles, preseed with credentials, raw logs or SSH keys as release assets.

## To create the first prerelease

1. Publish the repository to GitHub (see `docs/PUBLISH_ON_GITHUB.md`) and ensure GitHub Actions is enabled.
2. From a clean Git working copy, run tests with `bash scripts/test-static.sh`.
3. Commit changes, then create and push the version tag:

```bash
git tag -a v0.2.0-beta.1 -m 'Public installer beta'
git push origin main
git push origin v0.2.0-beta.1
```

4. GitHub Actions runs static checks, creates the macOS and Windows distribution ZIPs and SHA-256 file, then publishes a **pre-release** using the included release workflow. You can also publish manually using GitHub CLI after `python3 scripts/build_release.py --version v0.2.0-beta.1`:

```bash
gh release create v0.2.0-beta.1 dist/* --verify-tag --prerelease --title 'Surface Book edge-node installer beta' --notes-file docs/RELEASE_NOTES.md
```

**Do not claim hardware-tested Windows support until a real Windows→WSL→USB→Surface Book installation completes.** Mark these builds beta while validating.

## Release checklist

- No known credentials or local host identifiers in tracked source, screenshots or image metadata.
- No generated private ISO or customized Preseed/Wi-Fi profile in release assets.
- Verified release ZIP checksums and extracted-bundle folder structures.
- macOS and Windows builders start with clear disk-erasure warnings.
- USB instructions specify that **Rufus DD mode** is required for the SURFACELOG partition.
- Tests include Windows/PowerShell syntax checks in the Windows GitHub Actions job.
- Keep a changelog of installer bugs and avoid silently changing the pinned Debian point release.
