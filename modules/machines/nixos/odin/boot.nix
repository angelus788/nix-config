{
  boot.loader = {
    # 1. Enable systemd-boot
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;

    # 2. Mirror the configuration to both EFI partitions
    # This is a top-level loader option, NOT inside systemd-boot {}
    #mirroredBoots = [
    #  { devices = [ "nodev" ]; path = "/boot/efis/boot0"; }
    #  { devices = [ "nodev" ]; path = "/boot/efis/boot1"; }
    #];
  };

  # Make sure GRUB is disabled so it doesn't conflict
  boot.loader.grub.enable = false;
}
