{ config, lib, pkgs, ... }:
let
  net = config.homelab.networks;
  mainNet = net.external.heimdall;
  wg0Net = net.local.wireguard-ext;

  # 1. Safely extract Heimdall's external IPv4 address
  heimdallRawV4 = if mainNet ? v4 then (if builtins.isAttrs mainNet.v4 then mainNet.v4.address else mainNet.v4) else null;
  heimdallV4 = if heimdallRawV4 != null then lib.head (lib.splitString "/" heimdallRawV4) else null;

  # 2. Safely extract Heimdall's external IPv6 address
  heimdallRawV6 = if mainNet ? v6 then (if builtins.isAttrs mainNet.v6 then mainNet.v6.address else mainNet.v6) else null;
  heimdallV6 = if heimdallRawV6 != null then lib.head (lib.splitString "/" heimdallRawV6) else null;

  # 3. Cleanly derive IPv4 base subnet prefix (e.g., "10.5.0.1/24" -> "10.5.0")
  wg0V4Raw = wg0Net.cidr.v4 or "10.5.0.1/24";
  wg0V4Clean = lib.head (lib.splitString "/" wg0V4Raw);
  wg0V4Prefix = lib.concatStringsSep "." (lib.take 3 (lib.splitString "." wg0V4Clean));

  # 4. Cleanly derive IPv6 base subnet prefix (if configured)
  wg0V6Raw = wg0Net.cidr.v6 or null;
  wg0V6Prefix = if wg0V6Raw != null then lib.head (lib.splitString "/64" (lib.strings.removeSuffix "1/64" wg0V6Raw)) else null;

  # Helper to construct peer host addresses cleanly
  # (e.g., node 2 -> "10.5.0.2/32")
  wgIp = proto: nodeNum:
    if proto == "v4" then
      "${wg0V4Prefix}.${toString nodeNum}/32"
    else
      "${wg0V6Prefix}${toString nodeNum}/128";
in
{
  # ---------------------------------------------------------------------------
  # 1. Mesh Tunnel Hub (wg0) & WAN Configuration via systemd-networkd
  # ---------------------------------------------------------------------------
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
              (wgIp "v4" 2) # Evaluates to "10.5.0.2/32"
            ] ++ lib.optional (wg0V6Prefix != null) (wgIp "v6" 2);
          }
          /*
          {
            # tyr (Node 3)
            PublicKey = "IDBnOEFl3m9P2AF3PjHnRn8AjmqvhDYeRjSHG7ySYDc=";
            AllowedIPs = [
              (wgIp "v4" 3) # Evaluates to "10.5.0.3/32"
            ] ++ lib.optional (wg0V6Prefix != null) (wgIp "v6" 3);
          }
          */
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
            "${wg0V4Prefix}.1/24"
          ] ++ lib.optional (wg0V6Prefix != null) "${wg0V6Prefix}1/64";
        };
      };

      "10-wan0" = {
        matchConfig.Driver = "virtio_net";
        networkConfig = {
          IPv4Forwarding = true;
          IPv6Forwarding = true;

          Address = lib.filter (x: x != null) [
            mainNet.v4.address
            (if mainNet ? v6 then mainNet.v6.address else null)
          ];

          Gateway = lib.filter (x: x != null) [
            mainNet.v4.gateway
            (if mainNet ? v6 then mainNet.v6.gateway else null)
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

  # ---------------------------------------------------------------------------
  # 2. Kernel Routing & Firewall
  # ---------------------------------------------------------------------------
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    trustedInterfaces = [ "wg0" ];
    checkReversePath = "loose";
  };
}