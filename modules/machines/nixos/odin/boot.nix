{ lib, ... }:
{
  boot.loader = {
    grub.enable = lib.mkForce false;
    # 1. Enable systemd-boot
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = lib.mkForce "/boot/efis/boot0";


    # 2. Mirror the configuration to both EFI partitions
    # This is a top-level loader option, NOT inside systemd-boot {}
    #mirroredBoots = [
    #  { devices = [ "nodev" ]; path = "/boot/efis/boot0"; }
    #  { devices = [ "nodev" ]; path = "/boot/efis/boot1"; }
    #];
  };

}
  