{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

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
      force = true;
    };

    # 2. Generate the RON configuration file
    # We use a multi-line string ('') to ensure the RON format is exact
    home.file.".config/cosmic/com.system76.CosmicBackground/v1/all" = {
      text = ''
        (
            filter_by_theme: false,
            filter_method: Lanczos,
            output: "all",
            rotation_frequency: 3600,
            sampling_method: Alphanumeric,
            scaling_mode: Zoom,
            source: Path("${wallpaperDir}"),
        )
      '';
      force = true;
    };
  };
}
