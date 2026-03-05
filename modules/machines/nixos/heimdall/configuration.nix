{ config, pkgs, lib, modulesPath, ... }:

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
      #./wireguard.nix
      ../_common/apps/tailscale
    ];
}
