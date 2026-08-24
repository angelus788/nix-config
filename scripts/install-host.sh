#!/usr/bin/env bash
set -euo pipefail

# Usage check
HOSTNAME="${1:-}"
TARGET_IP="${2:-}"
SSH_PORT="${3:-22}"

if [ -z "$HOSTNAME" ] || [ -z "$TARGET_IP" ]; then
  echo "❌ Error: Missing arguments."
  echo "Usage:   $0 <hostname> <target-ip> [ssh-port]"
  echo "Example: $0 mimir 192.168.1.206 69"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
cd "$REPO_ROOT"

echo "======================================================"
echo " Preparing deployment for [$HOSTNAME] at [$TARGET_IP] (Post-install port: $SSH_PORT)"
echo "======================================================"

# 1. Ensure keys are pulled from Bitwarden
echo "--> Ensuring host keys are extracted..."
"$SCRIPT_DIR/backup-host-keys.sh"

BACKUP_DIR="$REPO_ROOT/host_keys_backup/$HOSTNAME"
if [ ! -f "$BACKUP_DIR/ssh_host_ed25519_key" ]; then
  echo "❌ Error: Host key for '$HOSTNAME' could not be found in $BACKUP_DIR." >&2
  exit 1
fi

STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT

echo "--> Staging SSH host keys into temporary extra-files..."
EXTRA_FILES_DIR="$STAGING_DIR/extra-files"

# Every host's _common/default.nix points services.openssh.hostKeys and
# age.identityPaths at /persist/ssh/ssh_host_ed25519_key (disko gives every
# host a /persist subvolume) — inject the backed-up key there for all hosts
# so it survives reinstalls and agenix can actually decrypt on first boot.
mkdir -p "$EXTRA_FILES_DIR/persist/ssh"
cp "$BACKUP_DIR/ssh_host_ed25519_key" "$EXTRA_FILES_DIR/persist/ssh/ssh_host_ed25519_key"
cp "$BACKUP_DIR/ssh_host_ed25519_key.pub" "$EXTRA_FILES_DIR/persist/ssh/ssh_host_ed25519_key.pub"

chmod 755 "$EXTRA_FILES_DIR/persist"
chmod 755 "$EXTRA_FILES_DIR/persist/ssh"
chmod 600 "$EXTRA_FILES_DIR/persist/ssh/ssh_host_ed25519_key"
chmod 644 "$EXTRA_FILES_DIR/persist/ssh/ssh_host_ed25519_key.pub"

# 4. Create a robust mock ssh-copy-id wrapper that forces your custom identity file
cat << 'MOCK_EOF' > "$STAGING_DIR/ssh-copy-id"
#!/usr/bin/env bash
set -euo pipefail

PUBKEY=""
TARGET=""
PORT="22"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i)
      PUBKEY="$2"
      shift 2
      ;;
    -p)
      PORT="$2"
      shift 2
      ;;
    -*|--*)
      shift
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

if [ -z "$PUBKEY" ] || [ -z "$TARGET" ]; then
  echo "Mock ssh-copy-id error: missing pubkey or target" >&2
  exit 1
fi

echo "--> [Mock ssh-copy-id] Uploading installer key to $TARGET on port $PORT..."
PUBKEY_CONTENT=$(cat "$PUBKEY")

SSH_AUTH_SOCK="" ssh -p "$PORT" -i "$HOME/.ssh/angelus" \
  -o "IdentitiesOnly=yes" \
  -o "StrictHostKeyChecking=no" \
  -o "UserKnownHostsFile=/dev/null" \
  "$TARGET" \
  "mkdir -p ~/.ssh && echo '$PUBKEY_CONTENT' >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
MOCK_EOF

chmod +x "$STAGING_DIR/ssh-copy-id"
export PATH="$STAGING_DIR:$PATH"

# 5. Clear known hosts for clean connection
ssh-keygen -R "$TARGET_IP" >/dev/null 2>&1 || true

echo "--> Launching nixos-anywhere..."
echo ""

# 6. Run nixos-anywhere with SSH_AUTH_SOCK cleared, build-on-remote, and custom options
SSH_AUTH_SOCK="" nix run github:nix-community/nixos-anywhere -- \
  --extra-files "$EXTRA_FILES_DIR" \
  --flake ".#$HOSTNAME" \
  --post-kexec-ssh-port "$SSH_PORT" \
  --build-on-remote \
  --ssh-option "IdentitiesOnly=yes" \
  --ssh-option "IdentityFile=$HOME/.ssh/angelus" \
  --ssh-option "StrictHostKeyChecking=no" \
  --ssh-option "UserKnownHostsFile=/dev/null" \
  "root@$TARGET_IP"

echo ""
echo "======================================================"
echo " Successfully deployed $HOSTNAME!"
echo "======================================================"