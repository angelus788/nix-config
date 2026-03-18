{ lib, ... }:
{
  boot.loader = {
    # Force GRUB off (overrides the shared module)
    grub.enable = lib.mkForce false;

    # Enable systemd-boot
    systemd-boot.enable = lib.mkForce true;

    # Force EFI variable access (overrides the shared module's "false")
    efi.canTouchEfiVariables = lib.mkForce true;

    # Direct the install to the first EFI partition
    efi.efiSysMountPoint = "/boot/efis/boot0";
  };
}
