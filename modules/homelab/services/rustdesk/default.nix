{ config, lib, ... }:
let
  service = "rustdesk";
  cfg = config.homelab.services.${service};
  homelab = config.homelab;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "rustdesk.${homelab.baseDomain}";
      description = "Hostname RustDesk clients use to reach the self-hosted signal/relay server";
    };
  };
  config = lib.mkIf cfg.enable {
    services.rustdesk-server = {
      enable = true;
      openFirewall = true;
      signal.relayHosts = [ cfg.url ];
    };
  };
}
