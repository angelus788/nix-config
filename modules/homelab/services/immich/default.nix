{
  config,
  lib,
  pkgs,
  inputs,
  ...
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
      # Main nixpkgs is pinned to 2.7.5, flagged insecure (CVE-2026-59258,
      # CVE-2026-82272). nixpkgs-unstable (already used elsewhere in this
      # repo, e.g. Forgejo's package override) has 3.1.0, not insecure, and
      # its `immich` package still exposes the `.machine-learning` passthru
      # the NixOS module's immich-machine-learning unit expects.
      package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.immich;
      group = homelab.group;
      enable = true;
      port = 2283;
      mediaLocation = "${cfg.mediaDir}";
    };
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = homelab.baseDomain;
      extraConfig = ''
        reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
      '';
    };
  };

}
