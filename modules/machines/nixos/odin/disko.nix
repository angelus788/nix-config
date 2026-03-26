{
  disko.devices = {
    disk = {
      # OS DRIVE: 500GB Crucial MX500
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_1947E228A4C0";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
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
                extraArgs = [ "-L" "odin-root" "-f" ];
                # Removed manual device path to avoid the "No such file" error
                subvolumes = {
                  "/root" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/persist" = { mountpoint = "/persist"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/var_log" = { mountpoint = "/var/log"; mountOptions = [ "compress=zstd" "noatime" ]; };
                };
              };
            };
          };
        };
      };

      # CACHE DRIVE: 500GB Crucial MX500
      cache = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_1947E228A5E2";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/mnt/cache";
                extraArgs = [ "-L" "odin-cache" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

      # DATA DRIVE 1
      data1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX92D62J3FRL";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/mnt/Data1";
                extraArgs = [ "-L" "data1" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

      # DATA DRIVE 2
      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX52DC0KY6JR";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/mnt/Data2";
                extraArgs = [ "-L" "data2" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

      # DATA DRIVE 3
      data3 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX22A82EZPTC";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/mnt/Data3";
                extraArgs = [ "-L" "data3" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

      # DATA DRIVE 4
      data4 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EFRX-68L0BN1_WD-WX11D28H9YHC";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/mnt/Data4";
                extraArgs = [ "-L" "data4" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

      # PARITY DRIVE 1
      parity1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EFRX-68L0BN1_WD-WX11D57REZ0V";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/mnt/Parity1";
                extraArgs = [ "-L" "parity1" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };
    };
  };
}
