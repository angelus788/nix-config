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
                extraArgs = [ "-n" "BOOT" ];
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-L" "odin-root" "-f" ];
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

      # CACHE DRIVE: Now Btrfs
      cache = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_1947E228A5E2";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-L" "cache" "-f" ];
                # Mapping as a top-level subvolume for simplicity, 
                # or just mount the root of the drive.
                subvolumes = {
                  "/cache" = {
                    mountpoint = "/cache";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };

      # DATA DRIVES (XFS)
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
                mountpoint = "/Data1";
                extraArgs = [ "-L" "data1" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

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
                mountpoint = "/Data2";
                extraArgs = [ "-L" "data2" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

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
                mountpoint = "/Data3";
                extraArgs = [ "-L" "data3" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

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
                mountpoint = "/Data4";
                extraArgs = [ "-L" "data4" "-f" ];
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };

      # PARITY DRIVE
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
                mountpoint = "/Parity1";
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
