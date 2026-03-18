{ lib, ... }:
{
  boot.loader = {
    # Force GRUB off (overrides the shared module)
    grub.enable = lib.mkForce false;

    # Enable systemd-boot
    systemd-boot.enable = lib.mkForce true;

    # Force UEFI variable access
    efi.canTouchEfiVariables = lib.mkForce true;

    # FORCE the mountpoint to override the long serial ID from the shared module
    efi.efiSysMountPoint = lib.mkForce "/boot/efis/boot0";
  };
}
