{ config, lib, ... }:
let
  net = config.homelab.networks;
  mainNet = net.external.heimdall;
  wg0Net = net.local.wireguard-ext;

  # Strip any netmask suffix (e.g., "/24") to get a clean IP for Endpoint
  heimdallIp = lib.head (lib.splitString "/" mainNet.v4.address);
  wg0V4Prefix = lib.strings.removeSuffix ".1" wg0Net.cidr.v4;
in
{
  systemd.network = {
    enable = true;

    netdevs = {
      "50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig = {
          ListenPort = 51821;
          PrivateKeyFile = config.age.secrets.wireguardPrivateKeyOdin.path;
        };
        wireguardPeers = [
          {
            # heimdall (Hub)
            PublicKey = "3pFGJLF2uGPagy76AlqzDbS0kYyi/x8RikKEoy5XiB4=";
            Endpoint = "${heimdallIp}:51820"; # Clean IP:Port
            PersistentKeepalive = 25;
            AllowedIPs = [
              "${wg0V4Prefix}.0/24"
              "${wg0Net.cidr.v6}/64"
            ];
          }
        ];
      };
    };

    networks = {
      "60-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = {
          Address = [
            "${lib.strings.removeSuffix ".1" wg0Net.cidr.v4}.2/24"
            "${wg0Net.cidr.v6}2/64"
          ];
        };
      };
    };
  };

  networking.firewall.allowedUDPPorts = [ 51821 ];
}
