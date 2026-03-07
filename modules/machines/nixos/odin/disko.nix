{ config ? { }, ... }:
let
  # OS Drive
  devices = config.zfs-root.bootDevices or [ "ata-CT500MX500SSD1_1947E228A4C0" ];
  diskMain = builtins.elemAt devices 0;

  # Cache Drive (New MX500)
  diskCache = "ata-CT500MX500SSD1_1947E228A5E2";

  # 6TB WDC Drives
  parityDisk = "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D57REZ0V";
  dataDisks = [
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX92D62J3FRL" # sdd (Index 0)
    "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D28H9YHC" # sde (Index 1)
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX52DC0KY6JR" # sdf (Index 2)
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX22A82EZPTC" # sdg (Index 3)
  ];
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/${diskMain}";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
            };
            bpool = { size = "4G"; content = { type = "zfs"; pool = "bpool"; }; };
            rpool = { size = "100%"; content = { type = "zfs"; pool = "rpool"; }; };
          };
        };
      };

      cache_ssd = {
        type = "disk";
        device = "/dev/disk/by-id/${diskCache}";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = { type = "zfs"; pool = "cache"; };
          };
        };
      };

      parity1 = {
        type = "disk";
        device = "/dev/disk/by-id/${parityDisk}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/parity1"; # Cleaned path
              extraArgs = [ "-L" "parity1" ];
            };
          };
        };
      };

      data1 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 0}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/data1"; extraArgs = [ "-L" "data1" ]; };
          };
        };
      };

      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 1}"; # Fixed Index
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/data2"; extraArgs = [ "-L" "data2" ]; };
          };
        };
      };

      data3 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 2}"; # Fixed Index
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/data3"; extraArgs = [ "-L" "data3" ]; };
          };
        };
      };

      data4 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 3}"; # Fixed Index
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/data4"; extraArgs = [ "-L" "data4" ]; };
          };
        };
      };
    };

    zpool = {
      bpool = {
        type = "zpool";
        datasets = {
          "nixos" = { type = "zfs_fs"; mountpoint = null; };
          "nixos/root" = { type = "zfs_fs"; mountpoint = "/boot"; options.mountpoint = "legacy"; };
        };
      };
      rpool = {
        type = "zpool";
        datasets = {
          "nixos" = { type = "zfs_fs"; mountpoint = null; };
          "nixos/empty" = { type = "zfs_fs"; mountpoint = "/"; options.mountpoint = "legacy"; };
          "nixos/home" = { type = "zfs_fs"; mountpoint = "/home"; options.mountpoint = "legacy"; };
          "nixos/nix" = { type = "zfs_fs"; mountpoint = "/nix"; options.mountpoint = "legacy"; };
          "nixos/persist" = { type = "zfs_fs"; mountpoint = "/persist"; options.mountpoint = "legacy"; };
        };
      };
      cache = {
        type = "zpool";
        datasets = {
          "data" = {
            type = "zfs_fs";
            mountpoint = "/cache"; # Explicitly mount this dataset at /cache
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
