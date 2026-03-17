{...}:
{
boot.loader.grub = {
  enable = true;
  zfsSupport = true;
  efiSupport = true;
  mirroredBoots = [
    { devices = [ "nodev" ]; path = "/boot/efis/boot0"; }
    { devices = [ "nodev" ]; path = "/boot/efis/boot1"; }
  ];
};

# Ensure the kernel is copied to the ZFS boot pool correctly
boot.loader.grub.copyKernels = true;
}