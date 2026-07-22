{ config, lib, ... }:
let
  net = config.homelab.networks;
  mainNet = net.external.heimdall;
  wg0Net = net.local.wireguard-ext;

  wgIp = proto: x:
    let
      base = lib.strings.removeSuffix ".1" wg0Net.cidr.${proto};
    in
    if proto == "v6" then "${base}${toString x}/128" else "${base}.${toString x}/32";
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
          ListenPort = 51820;
          PrivateKeyFile = config.age.secrets.wireguardPrivateKeyHeimdall.path;
        };
        wireguardPeers = [
          {
            # odin (Node 2)
            PublicKey = "pDUD3lURSne63c1uTAWgUhrPfrkm8KWtwErerH7KQyg=";
            AllowedIPs = [
              (wgIp "v4" 2)
              (wgIp "v6" 2)
            ];
          }
          {
            # # tyr (Node 3)
            # PublicKey = "IDBnOEFl3m9P2AF3PjHnRn8AjmqvhDYeRjSHG7ySYDc=";
            # AllowedIPs = [
            #   (wgIp "v4" 3)
            #   (wgIp "v6" 3)
            # ];
          }
        ];
      };
    };

    networks = {
      "60-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = {
          IPMasquerade = "both";
          IPv4Forwarding = true;
          IPv6Forwarding = true;
          Address = [
            "${lib.strings.removeSuffix ".1" wg0Net.cidr.v4}.1/24"
            "${wg0Net.cidr.v6}1/64"
          ];
        };
      };

      "10-wan0" = {
        matchConfig.Driver = "virtio_net";
        networkConfig = {
          IPv4Forwarding = true;
          IPv6Forwarding = true;

          Address = lib.filter (x: x != null) [
            mainNet.v4.address
            mainNet.v6.address
          ];

          Gateway = lib.filter (x: x != null) [
            mainNet.v4.gateway
            mainNet.v6.gateway
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

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    checkReversePath = "loose";
  };
}
