{...}:
{
boot.loader.grub = {
  enable = true;
  zfsSupport = true;
  efiSupport = true;
  copyKernels = true; # Helpful for ZFS to ensure kernels are on the FAT32 partition
  devices = [ "nodev" ];
  mirroredBoots = [
    { devices = [ "/dev/sda" ]; path = "/boot/efis/boot0"; }
    { devices = [ "/dev/sdb" ]; path = "/boot/efis/boot1"; }
  ];
};

# Ensure the kernel is copied to the ZFS boot pool correctly
boot.loader.grub.copyKernels = true;
}