{ config, lib, ... }:
let

  net = config.homelab.networks;
  mainNet = net.external.heimdall;
  wg0Net = net.local.wireguard-ext;

in
{
  systemd.network = {
    enable = true;
    netdevs = {
      "50-wg0" = {
        wireguardConfig = {
          ListenPort = 51820;
          PrivateKeyFile = config.age.secrets.wireguardPrivateKeyHeimdall.path;
        };
        wireguardPeers =
          let
            wgIp =
              proto: x:
              (
                (lib.strings.removeSuffix ".1" wg0Net.cidr.${proto})
                + (if proto == "v6" then "${toString x}/128" else ".${toString x}/32")
              );
          in
          [
            {
              # odin
              PublicKey = "3pFGJLF2uGPagy76AlqzDbS0kYyi/x8RikKEoy5XiB4=";
              AllowedIPs = [
                (wgIp "v4" 2)
                (wgIp "v6" 2)
              ];
            }
            {
              # tyr
              PublicKey = "IDBnOEFl3m9P2AF3PjHnRn8AjmqvhDYeRjSHG7ySYDc=";
              AllowedIPs = [
                (wgIp "v4" 3)
                (wgIp "v6" 3)
              ];
            }
          ];
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
      };
    };
    networks = {
      "60-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = lib.mkMerge [
          {
            IPMasquerade = "both";
            Address = [
              "${wg0Net.cidr.v4}/24"
              "${wg0Net.cidr.v6}1/64"
            ];
          }
        ];
      };
      "10-wan0" = {
        matchConfig.Driver = "virtio_net";
        networkConfig = {
          Address = lib.lists.remove null [
            mainNet.v4.address
            mainNet.v6.address
          ];
          DNS = [
            "9.9.9.9#dns.quad9.net"
            "149.112.112.112#dns.quad9.net"
            "2620:fe::fe#dns.quad9.net"
            "2620:fe::9#dns.quad9.net"
          ];
          DNSSEC = true;
          DNSOverTLS = true;
          IPv6AcceptRA = true;
          IPv6SendRA = false;
          LinkLocalAddressing = "ipv6";
          Gateway = lib.lists.remove null [
            mainNet.v4.gateway
            mainNet.v6.gateway
          ];
        };
        dhcpV6Config = {
          WithoutRA = "solicit";
          UseDelegatedPrefix = false;
          UseHostname = false;
          UseDNS = false;
          UseNTP = false;
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
