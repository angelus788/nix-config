{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  cfg = hl.services.deluge;
  ns = hl.services.wireguard-netns.namespace;
in
{
  options.homelab.services.deluge = {
    enable = lib.mkEnableOption "Deluge torrent client (bound to a Wireguard VPN network)";
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/deluge";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "deluge.${hl.baseDomain}";
    };
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "delugeweb"
        "deluge-web-proxy"
        "deluged"
      ];
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Deluge";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Torrent client";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "deluge.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Downloads";
    };
  };

  config = lib.mkIf cfg.enable {
    services.deluge = {
      enable = true;
      user = hl.user;
      group = hl.group;
      web = {
        enable = true;
        port = 8112;
      };
    };

    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8112
      '';
    };

    # REPLACE YOUR OLD systemd BLOCK WITH THIS:
    systemd = lib.mkIf hl.services.wireguard-netns.enable {
      # 1. Bind deluged to the WireGuard netns
      services.deluged = {
        bindsTo = [ "${ns}.service" ];
        wants = [ "network-online.target" ];
        after = [ "${ns}.service" "network-online.target" ];
        serviceConfig.NetworkNamespacePath = "/var/run/netns/${ns}";
      };

      # 2. Put delugeweb in the netns with deluged
      services.delugeweb = {
        bindsTo = [ "deluged.service" ];
        after = [ "deluged.service" ];
        serviceConfig.NetworkNamespacePath = "/var/run/netns/${ns}";
      };

      # 3. Host socket listening on port 8112
      sockets.deluge-web-proxy = {
        description = "Deluge WebUI Proxy Socket";
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = "127.0.0.1:8112";
        };
      };

      # 4. Proxy daemon running INSIDE the netns to forward host socket traffic to delugeweb
      services.deluge-web-proxy = {
        description = "Deluge WebUI NetNS Proxy Service";
        requires = [ "deluge-web-proxy.socket" "delugeweb.service" ];
        after = [ "deluge-web-proxy.socket" "delugeweb.service" ];
        serviceConfig = {
          NetworkNamespacePath = "/var/run/netns/${ns}";
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8112";
          PrivateTmp = true;
        };
      };
    };
  };
}