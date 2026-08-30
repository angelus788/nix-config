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
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "rustdesk-relay"
        "rustdesk-signal"
      ];
      description = "Actual systemd unit names created by services.rustdesk-server - the motd service table checks these instead of the nonexistent 'rustdesk' unit";
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
