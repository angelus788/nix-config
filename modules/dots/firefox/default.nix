{ pkgs, config, lib, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  guiEnabled = config.myHomeDots.enableGui or false;
in
{
  # Only apply this entire block on Linux GUI hosts
  programs.firefox = lib.mkIf (isLinux && guiEnabled) {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    
    # Enables communication between Bitwarden Desktop app and the Firefox extension
    nativeMessagingHosts = [
      pkgs.bitwarden-desktop
    ];
  };
}