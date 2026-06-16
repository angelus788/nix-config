{ config, pkgs, ... }:
{
  systemd.services.cosmic-greeter-wallpaper-sync = {
    description = "Sync COSMIC greeter wallpaper from wpaperd";
    after = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "cosmic-greeter";
      
      # CRITICAL: Disable temporary directory isolation so the 
      # service can see the real /tmp/wpaperd/current file
      PrivateTmp = false;

      ExecStart =
        let
          script = pkgs.writeShellScript "sync-cosmic-greeter" ''
            COSMIC_BG_DIR="/var/lib/cosmic-greeter/.config/cosmic/com.system76.CosmicBackground/v1"
            LOCAL_COPY="/var/lib/cosmic-greeter/current_wallpaper.png"

            TARGET_PATH=$(cat /tmp/wpaperd/current 2>/dev/null | tr -d '[:space:]')

            if [ -z "$TARGET_PATH" ] || [ ! -f "$TARGET_PATH" ]; then
              echo "Could not read wallpaper path link from /tmp/wpaperd/current" >&2
              exit 0 
            fi

            cp "$TARGET_PATH" "$LOCAL_COPY"
            chmod 644 "$LOCAL_COPY"

            mkdir -p "$COSMIC_BG_DIR"

            cat > "$COSMIC_BG_DIR/all" <<EOF
(
    filter_by_theme: false,
    filter_method: Lanczos,
    output: "all",
    rotation_frequency: 300,
    sampling_method: Alphanumeric,
    scaling_mode: Zoom,
    source: Path("$LOCAL_COPY"),
)
EOF

            cp "$COSMIC_BG_DIR/all" "$COSMIC_BG_DIR/same-on-all"
            echo "Greeter wallpaper successfully isolated and synced to: $LOCAL_COPY"
          '';
        in
        "${script}";
    };
  };

  systemd.timers.cosmic-greeter-wallpaper-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "5m"; 
    };
  };
}