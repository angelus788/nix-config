{ config
, lib
, ...
}:
let
  cfg = config.homelab.services.immich;
  homelab = config.homelab;
in
{
  options.homelab.services.immich = {
    enable = lib.mkEnableOption "Self-hosted photo and video management solution";
    user = lib.mkOption {
      default = config.homelab.user;
      type = lib.types.str;
      description = ''
        User to run the Immich container as
      '';
    };
    group = lib.mkOption {
      default = config.homelab.group;
      type = lib.types.str;
      description = ''
        Group to run the Immich container as
      '';
    };
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "immich-server"
        "immich-machine-learning"
      ];
    };
    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.homelab.mounts.fast}/Photos/Immich";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "photos.${homelab.baseDomain}";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Immich";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Self-hosted photo and video management solution";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "immich.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Media";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d ${cfg.mediaDir} 0775 immich ${homelab.group} - -" ];
    users.users.immich.extraGroups = [
      "video"
      "render"
    ];
    services.immich = {
      group = homelab.group;
      enable = true;
      #host = "0.0.0.0"; # Explicitly set to IPv4 loopback
      port = 2283;
      mediaLocation = "${cfg.mediaDir}";
      environment = {
        IMMICH_URL = "https://${cfg.url}";
        IMMICH_TRUSTED_PROXIES = "127.0.0.1";
      };
    };
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = homelab.baseDomain;
      extraConfig = ''
        reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
      '';
    };
  };

}
