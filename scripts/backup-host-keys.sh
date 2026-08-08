#!/usr/bin/env bash
set -euo pipefail

# Output directory for key backups
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/../host_keys_backup"
mkdir -p "$BACKUP_DIR"

# Host manifest (matches your Bitwarden item search terms)
HOSTS=(
  "thor"
  "odin"
  "heimdall"
  "mjolnir"
  "mayra"
  "mimir"
  "stormbreaker"
)

echo "======================================================"
echo " Starting Homelab SSH Host Key Extraction (Bitwarden)"
echo "======================================================"

# Ensure Bitwarden session is active
if [ -z "${BW_SESSION:-}" ]; then
  echo "Error: Bitwarden session is locked or unauthenticated." >&2
  echo "Please open a new terminal or run 'bw unlock' first." >&2
  exit 1
fi

for HOSTNAME in "${HOSTS[@]}" ; do
  HOST_DIR="$BACKUP_DIR/$HOSTNAME"
  mkdir -p "$HOST_DIR"
  chmod 700 "$HOST_DIR"

  echo ""
  echo "--> Fetching host keys for [$HOSTNAME] from Bitwarden vault..."

  # Find the unique ID using the flexible search filter that worked in your one-liner
  ITEM_ID=$(bw list items --search "$HOSTNAME" 2>/dev/null | jq -r '.[] | select(.sshKey != null) | .id' | head -n 1)

  if [ -z "$ITEM_ID" ] || [ "$ITEM_ID" = "null" ]; then
    echo "    ❌ Error: Could not find an SSH Key item for '$HOSTNAME' in Bitwarden. Skipping."
    continue
  fi

  # Fetch the fully decrypted item using its unique ID and extract the private key
  bw get item "$ITEM_ID" 2>/dev/null | jq -r '.sshKey.privateKey // empty' > "$HOST_DIR/ssh_host_ed25519_key"

  # Validate that the file is not empty
  if [ ! -s "$HOST_DIR/ssh_host_ed25519_key" ] || grep -q "^null$" "$HOST_DIR/ssh_host_ed25519_key"; then
    echo "    ❌ Error: Retrieved private key for '$HOSTNAME' was empty."
    rm -f "$HOST_DIR/ssh_host_ed25519_key"
    continue
  fi

  # Sanitize line endings (strip Windows carriage returns if any)
  tr -d '\r' < "$HOST_DIR/ssh_host_ed25519_key" > "$HOST_DIR/ssh_host_ed25519_key.tmp"
  mv "$HOST_DIR/ssh_host_ed25519_key.tmp" "$HOST_DIR/ssh_host_ed25519_key"
  chmod 600 "$HOST_DIR/ssh_host_ed25519_key"

  # Validate OpenSSH private key header
  if ! head -n 1 "$HOST_DIR/ssh_host_ed25519_key" | grep -q "BEGIN OPENSSH PRIVATE KEY"; then
    echo "    ❌ Error: The extracted file for '$HOSTNAME' is not a valid OpenSSH private key format."
    continue
  fi

  # Automatically generate the matching public key locally from the private key
  ssh-keygen -y -f "$HOST_DIR/ssh_host_ed25519_key" > "$HOST_DIR/ssh_host_ed25519_key.pub"
  chmod 644 "$HOST_DIR/ssh_host_ed25519_key.pub"

  FINGERPRINT=$(ssh-keygen -lf "$HOST_DIR/ssh_host_ed25519_key.pub" | awk '{print $2}')
  PUBKEY_STR=$(cat "$HOST_DIR/ssh_host_ed25519_key.pub")

  echo "    ✔ Host Key Restored to: $HOST_DIR/"
  echo "    ✔ Fingerprint:          $FINGERPRINT"
  echo "    ✔ Public Key:           $PUBKEY_STR"
done

echo ""
echo "======================================================"
echo " Restore complete! All host keys saved under: $BACKUP_DIR/"
echo "======================================================"
