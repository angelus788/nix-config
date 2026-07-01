# cosmic-dock
{ config, lib, pkgs, ... }:

let
  isLinux = !pkgs.stdenv.hostPlatform.isDarwin;
  isLinuxGui = isLinux && config.myHomeDots.enableGui;
in {
  # 1. Options must always be declared at the top-level of the module return set
  options.programs.cosmic.dock = {
    enable = lib.mkEnableOption "Declarative management of COSMIC dock shortcuts";

    shortcuts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of application desktop file IDs to pin to the COSMIC dock/app tray.";
      example = [
        "com.system76.CosmicFiles"
        "com.mitchellh.ghostty"
        "firefox"
        "bitwarden"
        "obsidian"
      ];
    };
  };

  # 2. Config block combines both conditions cleanly and evaluates 'cfg' safely
  config = let
    cfg = config.programs.cosmic.dock;
  in lib.mkIf (isLinuxGui && cfg.enable) {
    xdg.configFile."cosmic/com.system76.CosmicAppList/v1/favorites".text = ''
      [
      ${builtins.concatStringsSep "\n" (map (app: "  \"${app}\",") cfg.shortcuts)}
      ]
    '';
  };
}