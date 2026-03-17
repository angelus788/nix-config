{ lib, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Disable GRUB entirely
  boot.loader.grub.enable = false;

  # This is the "secret sauce" for mirrored ZFS boot with systemd-boot
  # It ensures the kernel/initrd are copied to both EFI partitions
  boot.loader.mirroredBoots = [
    { devices = [ "nodev" ]; path = "/boot/efis/boot0"; }
    { devices = [ "nodev" ]; path = "/boot/efis/boot1"; }
  ];

  networking.hostId = "your_8_digit_id";
  boot.supportedFilesystems = [ "zfs" ];
}