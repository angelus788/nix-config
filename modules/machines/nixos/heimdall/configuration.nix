{
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  # 1. Enable GRUB
  boot.loader.grub.enable = true;
  boot.loader.grub.configurationLimit = 3;

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
  # Ensure the agent has the necessary environment
  systemd.services.do-agent.after = [ "network-online.target" ];
  systemd.services.do-agent.wants = [ "network-online.target" ];

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

  boot.kernel.sysctl = {
    "net.ipv4.tcp_mtu_probing" = 1; # Allows the kernel to detect and fix MTU issues
  };

  networking = {
    useDHCP = false;
    hostName = "heimdall";
    nat.enable = false;
    firewall = {
      enable = true;
      allowedUDPPorts = [ 51820 ];
      allowedTCPPorts = [
        80
        443
      ];
    };
  };
  services.openssh = {
    openFirewall = true;
  };

  environment.systemPackages = [ pkgs.caddy ];

  home-manager.users.angelus.myHomeDots.enableGui = false;

  imports = [
    ../../../misc/avgtechguy.com
    ../../../misc/agenix
    ./homelab.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    ./digitalocean.nix
    ./secrets
    ./wireguard.nix
    ../../../apps/tailscale
  ];
}
