{ config, lib, pkgs, ... }:
let
  isLinux = !pkgs.stdenv.hostPlatform.isDarwin;
  isLinuxGui = isLinux && config.myHomeDots.enableGui;
in
{
  config = lib.mkIf config.myHomeDots.enableGui {

    # 1. Ensure Variety is installed
    home.packages = [ pkgs.variety ];

    # 2. Declaratively define variety.conf with forced symlinking
    xdg.configFile."variety/variety.conf" = {
      force = true; # Overwrites any unmanaged files blocking the symlink
      text = ''
        [general]
        change_on_start = True
        change_enabled = True
        change_interval = 300
        safe_mode = False
        internet_enabled = False
        icon = Dark
        clock_enabled = False
        quotes_enabled = False

        [sources]
        src1 = True|folder|/home/angelus/Workspace/Projects/wallpaper
        src2 = False|fetched|The Fetched folder
        src3 = False|favorites|The Favorites folder
        src4 = False|bing|Bing Photo of the Day
        src5 = False|unsplash|High-resolution photos from Unsplash.com
      '';
    };

    # 3. Optional: Automatically launch Variety on login
    xdg.configFile."autostart/variety.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Variety
      Comment=Variety Wallpaper Changer
      Exec=variety
      Icon=variety
      Terminal=false
      Categories=Utility;
    '';
  };
}