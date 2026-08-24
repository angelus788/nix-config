{
  lib,
  config,
  ...
}:
let
  networks = config.homelab.networks.local;
  internalInterfaces = lib.attrsets.mapAttrsToList (_: val: val.interface) networks;
  dhcpLeases = x: lib.attrsets.mapAttrsToList (_: value: value) networks.${x}.reservations;
  dnsCfg = x: {
    DNS = (
      lib.lists.remove null [
        networks.${x}.cidr.v4
        networks.${x}.cidr.v6
      ]
    );
    DNSSEC = false;
    DNSOverTLS = false;
  };
  dhcpCfgCommon = x: {
    EmitRouter = true;
    EmitDNS = true;
    DNS = networks.${x}.cidr.v4;
    EmitNTP = true;
    NTP = networks.${x}.cidr.v4;
    PoolOffset = 100;
    ServerAddress = "${networks.${x}.cidr.v4}/24";
    UplinkInterface = "wan0";
    DefaultLeaseTimeSec = 1800;
  };
  dhcpCfgDualStack = x: {
    dhcpServerConfig = lib.mkMerge [
      (dhcpCfgCommon x)
    ];
    ipv6PREF64Prefixes = [
      { Prefix = config.networking.jool.nat64.default.global.pool6; }
    ];
    ipv6Prefixes = [ { Prefix = "${networks.${x}.cidr.v6}/64"; } ];
    ipv6SendRAConfig = {
      DNS = "${networks.${x}.cidr.v6}";
      EmitDNS = true;
      EmitDomains = false;
    };
    networkConfig = lib.mkMerge [
      {
        IPv6AcceptRA = false;
        IPv6SendRA = true;
        LinkLocalAddressing = "ipv6";
        DHCPPrefixDelegation = true;
        DHCPServer = true;
        Address = [
          "${networks.${x}.cidr.v4}/24"
          "${networks.${x}.cidr.v6}/64"
        ];
        IPv4Forwarding = true;
        IPMasquerade = "ipv4";
      }
      (dnsCfg x)
    ];
    dhcpServerStaticLeases = (dhcpLeases x);

  };
  dhcpCfgIPv4Only = x: {
    dhcpServerConfig = (dhcpCfgCommon x);
    dhcpServerStaticLeases = (dhcpLeases x);
    networkConfig = lib.mkMerge [
      {
        DHCPServer = true;
        Address = "${networks.${x}.cidr.v4}/24";
        IPv4Forwarding = true;
        IPMasquerade = "ipv4";
      }
      (dnsCfg x)
    ];
  };
in
{
  imports = [
    ./firewall.nix
    ./dns.nix
  ];

  # Renaming NICs via services.udev.extraRules is unreliable: that rule file
  # runs at a generic priority, after systemd-udevd's own predictable-naming
  # rules (73-net-name-slot.rules etc.) have typically already claimed a name
  # for that boot's uevent — so the rename can silently lose the race. Every
  # systemd.network.networks stanza below matches on Name = "wan0"/"lan0" (in
  # addition to MAC), so a lost rename means that config never applies at all.
  # systemd.network.links is the mechanism systemd-udevd actually provides for
  # this and is guaranteed to run at the correct stage.
  systemd.network.links = {
    "10-wan0" = {
      matchConfig.MACAddress = "b0:22:7a:dc:78:28";
      linkConfig.Name = "wan0";
    };
    "10-lan0" = {
      matchConfig.MACAddress = "c0:18:03:65:51:15";
      linkConfig.Name = "lan0";
    };
  };

  homelab.motd.networkInterfaces = lib.mapAttrsToList (_: v: v.interface) networks;

  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    config.networkConfig.IPv6Forwarding = true;
    networks = {
      "10-wan0" = {
        matchConfig = {
          Name = "wan0";
          MACAddress = "b0:22:7a:dc:78:28";
        };
        networkConfig = {
          DHCP = true;
          IPv6AcceptRA = true;
          LinkLocalAddressing = "ipv6";
          IPv4Forwarding = true;
          DNS = "127.0.0.1";
          DNSSEC = false;
          DNSOverTLS = false;
        };
        dhcpV4Config = {
          UseHostname = false;
          UseDNS = false;
          UseNTP = false;
          UseSIP = false;
          ClientIdentifier = "mac";
          UseRoutes = false;
          UseGateway = true;
        };
        ipv6AcceptRAConfig = {
          UseDNS = false;
          DHCPv6Client = true;
        };
        dhcpV6Config = {
          WithoutRA = "solicit";
          UseDelegatedPrefix = true;
          UseHostname = false;
          UseDNS = false;
          UseNTP = false;
        };
        linkConfig.RequiredForOnline = "routable";
      };

      "20-lan0" = {
        matchConfig = {
          Name = "lan0";
          MACAddress = "c0:18:03:65:51:15";
        };
        networkConfig.Bridge = "br0";
        linkConfig = {
          Unmanaged = "yes";
          RequiredForOnline = "enslaved";
        };
      };

      "30-iot" = lib.mkMerge [
        {
          matchConfig.Name = "iot";
          linkConfig.RequiredForOnline = false;
        }
        (dhcpCfgIPv4Only "iot")
      ];
      "30-guest" = lib.mkMerge [
        {
          matchConfig.Name = "guest";
          linkConfig.RequiredForOnline = false;
        }
        (dhcpCfgDualStack "guest")
      ];

      "40-br0" = lib.mkMerge [
        {
          matchConfig.Name = "br0";
          networkConfig.VLAN = [
            "iot"
            "guest"
          ];
          linkConfig.RequiredForOnline = "routable";
          dhcpPrefixDelegationConfig.SubnetId = "0x1";
        }
        (dhcpCfgDualStack "lan")
      ];
      "60-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = lib.mkMerge [
          {
            IPMasquerade = "both";
            Address = [
              "${networks.wireguard.cidr.v4}/24"
              "${networks.wireguard.cidr.v6}/64"
            ];
          }
        ];
      };
    };

    netdevs = {
      "50-br0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
        bridgeConfig = {
          VLANFiltering = true;
        };
      };
      "50-iot" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "iot";
        };
        vlanConfig.Id = 3;
      };
      "50-guest" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "guest";
        };
        vlanConfig.Id = 5;
      };
      "50-wg0" = {
        wireguardConfig = {
          ListenPort = 51820;
          PrivateKeyFile = config.age.secrets.wireguardPrivateKeyMimir.path;
        };
        wireguardPeers =
          let
            # Drop the router's own last address segment (e.g. the ".1" in
            # "10.8.1.1", or the "1" after "::" in "fd00:2::1") and append the
            # peer's segment instead. Splitting on the real separator handles
            # both protocols correctly — a literal `removeSuffix ".1"` only
            # coincidentally works for IPv4 and silently no-ops on IPv6, since
            # "fd00:2::1" doesn't end with the two-character string ".1".
            wgIp =
              proto: x:
              let
                sep = if proto == "v6" then ":" else ".";
                segments = lib.splitString sep networks.wireguard.cidr.${proto};
                prefix = lib.concatStringsSep sep (
                  lib.lists.take (builtins.length segments - 1) segments
                );
              in
              "${prefix}${sep}${toString x}${if proto == "v6" then "/128" else "/32"}";
          in
          [
            {
              # meredith
              PublicKey = "rAkXoiMoxwsKaZc4qIpoXWxD9HBCYjsAB33hPB7jBBg=";
              AllowedIPs = [
                (wgIp "v4" 2)
                (wgIp "v6" 2)
              ];
            }
            {
              # iphone
              PublicKey = "6Nh1FrZLJBv7kb/jlR+rkCsWDoiSq9jpOQo68a6vr0Q=";
              AllowedIPs = [
                (wgIp "v4" 3)
                (wgIp "v6" 3)
              ];
            }
            {
              # pixel
              PublicKey = "G4YNJHjG8n8v3v5gZjMdE4d+9tXAf/Yng571rk8t2Gk=";
              AllowedIPs = [
                (wgIp "v4" 4)
                (wgIp "v6" 4)
              ];
            }
          ];
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
      };
    };
  };

  networking = {
    jool = {
      nat64.default.global.pool6 = "64:ff9b::/96";
      enable = true;
    };
    hostName = "mimir";
    domain = "${config.networking.hostName}.${config.homelab.baseDomain}";
    search = [ config.homelab.baseDomain ];
  };

  services = {
    avahi = {
      enable = true;
      allowInterfaces = internalInterfaces;
      reflector = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
    journald = {
      rateLimitBurst = 0;
      extraConfig = "SystemMaxUse=50M";
    };
  };
}