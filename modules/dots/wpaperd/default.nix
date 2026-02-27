{ config, lib, pkgs, ... }:

let
  isLinux = !pkgs.stdenv.hostPlatform.isDarwin;
  wallpaperPath = "${config.home.homeDirectory}/Workspace/Projects/wallpaper";
in
{
  config = lib.mkIf isLinux {
    home.packages = with pkgs; [ wpaperd ];

    # 1. Desktop Wallpaper Daemon (wpaperd)
    xdg.configFile."wpaperd/config.toml".text = ''
      [default]
      path = "${wallpaperPath}"
      duration = "5m"
    '';

    # 2. COSMIC Lock Screen (Greeter) Settings
    # COSMIC stores its settings in TOML files under ~/.config/cosmic/
    xdg.configFile."cosmic/com.system76.CosmicGreeter/v1/background".text = ''
      path = "${wallpaperPath}"
      source = "Path"
      filter_method = "Lanczos"
      sampling_method = "Alphanumeric"
    '';

    # 3. Systemd Service
    systemd.user.services.wpaperd = {
      Unit = {
        Description = "Wallpaper daemon";
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


