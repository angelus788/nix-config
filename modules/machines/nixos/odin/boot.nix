{...}:
{
boot.loader.grub = {
  enable = true;
  zfsSupport = true;
  efiSupport = true;
  # Fixes the ASRock "cannot find bootloader" issue
  efiInstallAsRemovable = true; 
  # Points directly to the partition on your Crucial SSD
  mirroredBoots = [
    { 
      devices = [ "nodev" ]; 
      path = "/boot/efis/ata-CT500MX500SSD1_1947E228A4C0-part1"; 
    }
  ];
};

# Ensure the kernel is copied to the ZFS boot pool correctly
boot.loader.grub.copyKernels = true;
}