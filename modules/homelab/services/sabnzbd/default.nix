{ config, lib, ... }:
let
  service = "sabnzbd";
  cfg = config.homelab.services.${service};
  homelab = config.homelab;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "sabnzbd.${homelab.baseDomain}";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "SABnzbd";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "The free and easy binary newsreader";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "sabnzbd.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Downloads";
    };
  };
  config = lib.mkIf cfg.enable {
    services.${service} = {
      enable = true;
      user = homelab.user;
      group = homelab.group;

      # 1. Explicitly nullify the deprecated option to suppress the warning
      configFile = null;

      # 2. OPTIONAL: Set this to true if you want to allow mutating settings in the GUI.
      # If false (default), Nix renders the config file as immutable.
      allowConfigWrite = true;

      # 3. Supply your base structure here. Even an empty attrset satisfies the module 
      # and lets SABnzbd initialize gracefully using your configured state directory.
      settings = {
        # misc = {
        #   port = 8080;
        # };
      };
    };
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = homelab.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8080
      '';
    };
  };

}
