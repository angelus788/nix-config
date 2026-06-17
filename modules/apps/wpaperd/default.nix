{ config, pkgs, ... }:
{
  # 1. The Watcher: Monitors the bridge file for changes
  systemd.paths.cosmic-greeter-wallpaper-sync = {
    description = "Watch for wpaperd wallpaper changes to sync to COSMIC greeter";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      # This triggers the service immediately whenever this file is modified
      PathModified = "/tmp/cosmic_current_wallpaper";
    };
  };

  # 2. The Worker: Runs ONLY when triggered by the path unit
  systemd.services.cosmic-greeter-wallpaper-sync = {
    description = "Sync COSMIC greeter wallpaper from wpaperd";
    
    serviceConfig = {
      Type = "oneshot";
      User = "cosmic-greeter";
      PrivateTmp = false;

      ExecStart =
        let
          script = pkgs.writeShellScript "sync-cosmic-greeter" ''
            COSMIC_BG_DIR="/var/lib/cosmic-greeter/.config/cosmic/com.system76.CosmicBackground/v1"
            LOCAL_COPY="/var/lib/cosmic-greeter/current_wallpaper.png"

            # Read the explicit path from our bridge file
            TARGET_PATH=$(cat /tmp/cosmic_current_wallpaper 2>/dev/null | tr -d '[:space:]')

            if [ -z "$TARGET_PATH" ] || [ ! -f "$TARGET_PATH" ]; then
              echo "Invalid or missing wallpaper path in bridge file." >&2
              exit 0 
            fi

            # Prevent unnecessary I/O if the image hasn't actually changed
            if cmp -s "$TARGET_PATH" "$LOCAL_COPY"; then
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
          '';
        in
        "${script}";
    };
  };
}