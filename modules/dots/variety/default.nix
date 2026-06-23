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
    change_on_start = True
    change_enabled = True
    change_interval = 300
    safe_mode = False
    internet_enabled = False
    icon = Dark
    
    # Force Variety to look only at your folder
    # Format: src = <Enabled>|<Type>|<Path>
    # Note: Using explicit paths without homeDirectory variable if possible 
    # to avoid parser confusion.
    src1 = True|folder|/home/angelus/Workspace/Projects/wallpaper
    
    # Disable all other sources explicitly
    src2 = False|fetched|The Fetched folder
    src3 = False|favorites|The Favorites folder
    src4 = False|bing|Bing Photo of the Day
    src5 = False|unsplash|High-resolution photos from Unsplash.com
    
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