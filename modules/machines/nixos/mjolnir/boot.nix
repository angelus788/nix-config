{ lib, ... }:
{
  boot = {
    # Secure boot configuration
    bootspec.enable = true;
    loader.systemd-boot.enable = lib.mkForce false;
    loader.efi.canTouchEfiVariables = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl"; #"/etc/secureboot";
    };

    initrd = {
      availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
    };


    kernelModules = [
      "kvm_intel"
      "vhost_vsock"
    ];

    # Use the latest Linux kernel, rather than the default LTS
    # kernelPackages = pkgs.linuxPackages_latest;
  };
}