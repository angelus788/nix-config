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
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX92D62J3FRL" # sdd
    "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D28H9YHC" # sde
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX52DC0KY6JR" # sdf
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX22A82EZPTC" # sdg
  ];
in
{
  disko.devices = {
    disk = {
      # --- OS SSD (ZFS rpool) ---
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

      # --- Cache SSD (ZFS cache pool) ---
      cache_ssd = {
        type = "disk";
        device = "/dev/disk/by-id/${diskCache}";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "cache"; # This names the pool 'cache'
            };
          };
        };
      };

      # --- Parity & Data HDDs (XFS + Labels) ---
      parity1 = {
        type = "disk";
        device = "/dev/disk/by-id/${parityDisk}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/parity1"; extraArgs = [ "-L" "parity1" ]; };
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
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data1"; extraArgs = [ "-L" "data1" ]; };
          };
        };
      };
      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 3}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data4"; extraArgs = [ "-L" "data2" ]; };
          };
        };
      };
      data3 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 3}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data4"; extraArgs = [ "-L" "data3" ]; };
          };
        };
      };
      data4 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 3}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data4"; extraArgs = [ "-L" "data4" ]; };
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
      # --- NEW CACHE POOL ---
      cache = {
        type = "zpool";
        datasets = {
          "data" = {
            type = "zfs_fs";
            # This allows it to be used as rpool/nixos/data or cache/data
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
