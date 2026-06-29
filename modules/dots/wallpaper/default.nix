{ config, inputs, lib, pkgs, ... }:

let
  isLinux = !pkgs.stdenv.hostPlatform.isDarwin;
  isLinuxGui = isLinux && config.myHomeDots.enableGui;
  # Define the directory path
  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpaper";
in 
{
  config = lib.mkIf isLinuxGui {
  # 1. Deploy the wallpaper files from your flake input
  home.file."Pictures/Wallpaper" = {
    source = inputs.wallpaper;
    recursive = true;
  };

  # 2. Generate the RON configuration file
  # We use a multi-line string ('') to ensure the RON format is exact
  home.file.".config/cosmic/com.system76.CosmicBackground/v1/config.ron" = {
    text = ''
      (
          slideshow_enabled: true,
          slideshow_timer: 3600,
          shuffle: true,
          wallpaper_path: "${wallpaperDir}",
      )
    '';
    force = true; 
  };
  };
}