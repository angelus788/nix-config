{ config, lib, pkgs, ... }:
let
  isLinux = !pkgs.stdenv.hostPlatform.isDarwin;
  isLinuxGui = isLinux && config.myHomeDots.enableGui;
  wallpaperPath = "${config.home.homeDirectory}/Workspace/Projects/wallpaper";
  homeDir = config.home.homeDirectory;

  syncCosmicWallpaper = pkgs.writeShellScript "sync-cosmic-wallpaper" ''
    # wpaperd passes the screen name as $1 and the image path as $2
    WALLPAPER="$2"
    COSMIC_BG_DIR="${homeDir}/.config/cosmic/com.system76.CosmicBackground/v1"

    if [ -z "$WALLPAPER" ]; then
      STATE_DIR="${homeDir}/.local/state/wpaperd/wallpapers"
      WALLPAPER=$(readlink -f "$STATE_DIR"/* 2>/dev/null | head -n 1)
    fi

    if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
      exit 1
    fi

    # --- CRITICAL ADDITION: Write to a bridge file for the system service ---
    echo "$WALLPAPER" > /tmp/cosmic_current_wallpaper
    chmod 644 /tmp/cosmic_current_wallpaper
    # ------------------------------------------------------------------------

    mkdir -p "$COSMIC_BG_DIR"

    RON_CONTENT=$(cat <<EOF
(
    filter_by_theme: false,
    filter_method: Lanczos,
    output: "all",
    rotation_frequency: 300,
    sampling_method: Alphanumeric,
    scaling_mode: Zoom,
    source: Path("$WALLPAPER"),
)
EOF
)

    echo "$RON_CONTENT" > "$COSMIC_BG_DIR/all"
    echo "$RON_CONTENT" > "$COSMIC_BG_DIR/same-on-all"

    for monitor_file in "$COSMIC_BG_DIR"/*; do
        if [ -f "$monitor_file" ]; then
            filename=$(basename "$monitor_file")
            if [ "$filename" != "all" ] && [ "$filename" != "same-on-all" ]; then
                echo "$RON_CONTENT" > "$monitor_file"
            fi
        fi
    done
  '';
in
{
  config = lib.mkIf isLinuxGui {
    home.packages = with pkgs; [ wpaperd ];

    xdg.configFile."wpaperd/config.toml".text = ''
      [default]
      path = "${wallpaperPath}"
      duration = "5m"
      sorting = "random"
      exec = "${syncCosmicWallpaper}"
    '';

    systemd.user.services.wpaperd = {
      Unit = {
        Description = "Wallpaper daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.wpaperd}/bin/wpaperd";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}