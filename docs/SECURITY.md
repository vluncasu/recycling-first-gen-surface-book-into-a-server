# Security, privacy and release checklist

## Before publishing

Never add any of the following to public Git history:

- generated ISO images, USB images, or raw preseed files;
- Wi-Fi SSIDs that identify a private location, Wi-Fi passwords, account password hashes;
- `.nmconnection` Wi-Fi profiles, local `.env` values, app/database secrets;
- SSH private keys, Tailscale authentication URLs or keys, machine IDs;
- raw diagnostic logs, router settings, private/public IP metadata or MAC addresses tied to the deployment;
- device serial numbers, home photos exposing identifying labels, terminal title bars with local account names.

The shared documentation intentionally uses fictional identifiers. `installer/preseed.cfg.template` and `installer/WiFi.nmconnection.template` contain **placeholders**. The builder creates real credentials in a temporary private directory and generated ISO; the ISO must remain private.

## Protect SSH

1. Start with password access only if essential. Confirm SSH public-key login from a second session.
2. Use a separate per-device SSH key with a passphrase; the build helper currently creates an unencrypted key only as an onboarding convenience if none exists. Prefer a protected key for production.
3. After verifying keys, consider `PasswordAuthentication no` in `sshd_config.d`; always run `sudo sshd -t` before a reload. Keep a rollback session.
4. Disable root SSH logins. Restrict management access with Tailscale ACLs or firewall policy.
5. Avoid public port forwards for SSH or Cockpit unless backed by a deliberate security architecture.
6. Do not assume Docker-published ports obey all `ufw` rules; consult [Docker firewall guidance](https://docs.docker.com/engine/install/debian/#firewall-limitations).

## Untrusted logs and script execution

Read and audit `*.command` before running it. Do not execute arbitrary scripts copied from forum posts. These installers modify boot state and partitions; a malformed guard can erase the wrong disk. Scrub log files for hostnames, serials and credentials before opening public issues. Use truncated, redacted excerpts.

## Credential rotation

If you used a password in an earlier experiment and ever posted it in chat, screenshots or diagnostics, treat that credential as exposed. Change the Linux account password with `passwd`, update Wi-Fi credentials if appropriate, and remove stale private ISOs/USB copies. Never assume a salted password hash makes public distribution of boot media secure.

## No guarantees

The public source is a transparent and conservative replication aid; no physical hardware acceptance test has been made for every variant. The original successful test is a single field observation, not security certification or production availability certification.
