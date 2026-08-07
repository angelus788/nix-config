#!/usr/bin/env bash
set -euo pipefail

# Output directory for key backups
BACKUP_DIR="./host_keys_backup"
mkdir -p "$BACKUP_DIR"

# Host manifest over Tailscale
# Format: "hostname" or "hostname:port"
HOSTS=(
  "thor:69"
  "odin:69"
  "heimdall:69"
  "mjolnir:69"
  "mayra:69"
)

SSH_USER="angelus"
IDENTITY_FILE="$HOME/.ssh/angelus"

echo "======================================================"
echo " Starting Homelab SSH Host Key Extraction (Tailscale)"
echo "======================================================"

for ENTRY in "${HOSTS[@]}"; do
  # Default port to 22 if not explicitly specified
  if [[ "$ENTRY" == *":"* ]]; then
    IFS=":" read -r HOSTNAME PORT <<< "$ENTRY"
  else
    HOSTNAME="$ENTRY"
    PORT="22"
  fi
  
  HOST_DIR="$BACKUP_DIR/$HOSTNAME"
  mkdir -p "$HOST_DIR"
  chmod 700 "$HOST_DIR"

  echo ""
  echo "--> Fetching host keys for [$HOSTNAME] over Tailscale (Port $PORT)..."

  SSH_CMD="ssh -p $PORT -i $IDENTITY_FILE -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"

  if [ "$HOSTNAME" = "tyr" ] || [ "$HOSTNAME" = "$(hostname)" ]; then
    # Local host direct copy if running on the target itself
    sudo cat /persist/ssh/ssh_host_ed25519_key > "$HOST_DIR/ssh_host_ed25519_key"
    sudo cat /persist/ssh/ssh_host_ed25519_key.pub > "$HOST_DIR/ssh_host_ed25519_key.pub"
  else
    # Remote host SSH pull over Tailscale
    $SSH_CMD "$SSH_USER@$HOSTNAME" "sudo cat /persist/ssh/ssh_host_ed25519_key" > "$HOST_DIR/ssh_host_ed25519_key"
    $SSH_CMD "$SSH_USER@$HOSTNAME" "sudo cat /persist/ssh/ssh_host_ed25519_key.pub" > "$HOST_DIR/ssh_host_ed25519_key.pub"
  fi

  chmod 600 "$HOST_DIR/ssh_host_ed25519_key"
  chmod 644 "$HOST_DIR/ssh_host_ed25519_key.pub"

  FINGERPRINT=$(ssh-keygen -lf "$HOST_DIR/ssh_host_ed25519_key.pub" | awk '{print $2}')
  PUBKEY_STR=$(cat "$HOST_DIR/ssh_host_ed25519_key.pub")

  echo "    ✔ Host Key Saved to: $HOST_DIR/"
  echo "    ✔ Fingerprint:       $FINGERPRINT"
  echo "    ✔ Public Key:        $PUBKEY_STR"
done

echo ""
echo "======================================================"
echo " Backup complete! All host keys saved under: $BACKUP_DIR/"
echo "======================================================"
