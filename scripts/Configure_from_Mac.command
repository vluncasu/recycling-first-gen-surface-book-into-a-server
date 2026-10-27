#!/bin/bash
# One Mac command, connects to remote host and invokes postconfiguration under sudo.
set -Eeuo pipefail
cd "$(dirname "$0")"
read -r -p 'SSH username [surfaceadmin]: ' USER
USER="${USER:-surfaceadmin}"
read -r -p 'Host [surfacebook-node.local]: ' HOST
HOST="${HOST:-surfacebook-node.local}"
[[ "$USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo 'Invalid user'; exit 1; }
[[ "$HOST" =~ ^[a-zA-Z0-9._-]+$ ]] || { echo 'Invalid hostname'; exit 1; }
echo "Connecting to $USER@$HOST; review host fingerprint on first SSH use."
REMOTE_PATH=".edge-postconfigure-$$.sh"
scp "postconfigure-remote.sh" "$USER@$HOST:$REMOTE_PATH"
ssh -t "$USER@$HOST" "sudo bash '$REMOTE_PATH'; code=\$?; rm -f '$REMOTE_PATH'; exit \$code"
echo 'Remote postconfiguration completed. Run scripts/audit-node.sh on the host for a local report.'
