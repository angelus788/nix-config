{ config, pkgs, lib, modulesPath, ... }:

let

  net = config.homelab.networks;
  mainNet = net.external.heimdall;
  # This provides a fallback empty string if the attribute is missing
  #mainNet = net.external.heimdall or { };
  #mainNet =
  #  if lib.hasAttr "heimdall" net.external
  #  then net.external.heimdall
  #  else {
  #    interface = "eth-fail";
  #    v4 = { address = "159.65.167.45/24"; gateway = "159.65.160.1"; };
  #    v6 = { address = "fe80::d893:84ff:fe33:1370/64"; gateway = "fe80::1"; };
  #  };
  wg0Net = net.local.wireguard-ext;

in

{
  # 1. Enable GRUB
  boot.loader.grub.enable = true;

  # 2. CLEAR the duplicated list and force it to be exactly what we want
  # This stops the 'mirroredBoots' error by overriding the cloud default.
  boot.loader.grub.devices = lib.mkForce [ "/dev/vda" ];

  # 3. Also force the root filesystem if you get a 'duplicate mount' error
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-partlabel/disk-main-root";
    fsType = "ext4";
  };

  # Enables the DigitalOcean Agent
  services.do-agent.enable = true;

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200"
  ];

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
              PublicKey = "9yWSFKHsb2NSoHG5YvU4/ZfL2TycVBLLZqT/jBFj/2A=";
              AllowedIPs = [
                (wgIp "v4" 2)
                (wgIp "v6" 2)
              ];
            }
            {
              # mjolnir
              PublicKey = "CKvi5UNIMlKFbOz81Unes7dYqUgcMowL4aJzFj7ivh4=";
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
  networking = {
    useDHCP = false;
    hostName = "heimdall";
    nat.enable = false;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 51820 ];
    };
  };
  services.openssh = {
    openFirewall = true;
  };
  imports =
    [
      ../../../misc/avgtechguy.com
      ../../../misc/agenix
      ./homelab.nix
      (modulesPath + "/profiles/qemu-guest.nix")
      ./disko.nix
      ./digitalocean.nix
      ./secrets
      ../_common/apps/tailscale
    ];
}
