{ config, lib, ... }:
let
  net = config.homelab.networks;
  wg0Net = net.local.wireguard-ext;
  heimdallWan = net.external.heimdall.v4.address; # Heimdall's VPS IP
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
          # Path to odin's private key secret
          PrivateKeyFile = config.age.secrets.wireguardPrivateKeyOdin.path;
        };
        wireguardPeers = [
          {
            # Heimdall VPS
            PublicKey = "3pFGJLF2uGPagy76AlqzDbS0kYyi/x8RikKEoy5XiB4=";
            Endpoint = "${heimdallWan}:51820";
            
            # Route traffic for the WireGuard subnet to Heimdall
            AllowedIPs = [
              "${wg0Net.cidr.v4}/24"
              "${wg0Net.cidr.v6}/64"
            ];
            
            # Keeps the connection open through Mimir/local NAT
            PersistentKeepalive = 25;
          }
        ];
      };
    };
    networks = {
      "60-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = {
          Address = [
            "10.5.0.2/24" # Matching wgIp "v4" 2
            "fd00::2/64"   # Matching wgIp "v6" 2
          ];
        };
      };
    };
  };
}