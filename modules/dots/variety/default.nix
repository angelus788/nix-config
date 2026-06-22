{ config, lib, pkgs, ... }:
let
  isLinux = !pkgs.stdenv.hostPlatform.isDarwin;
  isLinuxGui = isLinux && config.myHomeDots.enableGui;
in
  {
  config = lib.mkIf config.myHomeDots.enableGui {

  # 1. Ensure Variety is installed
  home.packages = [ pkgs.variety ];

  # 2. Declaratively define variety.conf
  xdg.configFile."variety/variety.conf".text = ''
    # General behavior
    change_on_start = True
    change_enabled = True
    change_interval = 300
    safe_mode = False
    
    # Copy/Favorites configuration
    copyto_enabled = False
    copyto_folder = Default

    # Wallpaper Sources
    # Syntax: srcX = <Enabled: True/False>|<Type>|<Path or URL>
    src1 = True|favorites|The Favorites folder
    src2 = False|fetched|The Fetched folder
    src3 = True|folder|${config.home.homeDirectory}/Workspace/Projects/wallpaper
    src4 = False|desktoppr|Random wallpapers from Desktoppr.co
    src5 = False|bing|Bing Photo of the Day
    src6 = False|unsplash|High-resolution photos from Unsplash.com
    
    # Visual Tweaks
    clock_enabled = False
    quotes_enabled = False
  '';

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