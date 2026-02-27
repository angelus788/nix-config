{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda"; # Standard for DigitalOcean VirtIO
        content = {
          type = "gpt";
          partitions = {
            # 1. BIOS Boot: Essential for GRUB on GPT/BIOS systems (DigitalOcean)
            boot = {
              size = "1M";
              type = "EF02"; # BIOS boot partition code
              priority = 1; # Ensure it's at the beginning of the disk
            };
            # 2. Root: The main filesystem
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
