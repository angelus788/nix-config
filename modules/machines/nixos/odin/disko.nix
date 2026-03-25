{
  disko.devices = {
    disk = {
      # OS Drive (Currently sda)
      boot0 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_1947E228A4C0";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # BIOS compatibility
              priority = 1;
            };
            ESP = {
              size = "1G";
              type = "EF00";
              priority = 2;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/var_log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };

      # New Cache Drive (sdb)
      # Note: Replace the ID below with the actual ID for your second 500GB SSD
      cache0 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_XXXXXXXXXXXX"; # <-- UPDATE THIS ID
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/mnt/cache";
                mountOptions = [ "defaults" "nofail" ];
              };
            };
          };
        };
      };

      # Data Pool (5.5TB Drives)
      Data1 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX92D62J3FRL"; content = { type = "gpt"; partitions = { primary = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/Data1"; mountOptions = [ "nofail" ]; }; }; }; }; };
      Data2 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX52DC0KY6JR"; content = { type = "gpt"; partitions = { primary = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/Data2"; mountOptions = [ "nofail" ]; }; }; }; }; };
      Data3 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX22A82EZPTC"; content = { type = "gpt"; partitions = { primary = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/Data3"; mountOptions = [ "nofail" ]; }; }; }; }; };
      Data4 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD60EFRX-68L0BN1_WD-WX11D28H9YHC"; content = { type = "gpt"; partitions = { primary = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/Data4"; mountOptions = [ "nofail" ]; }; }; }; }; };
      Parity1 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD60EFRX-68L0BN1_WD-WX11D57REZ0V"; content = { type = "gpt"; partitions = { primary = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/Parity1"; mountOptions = [ "nofail" ]; }; }; }; }; };
    };
  };
}
