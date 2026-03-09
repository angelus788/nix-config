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
      # --- OS SSD ---
      main = {
        type = "disk";
        device = "/dev/disk/by-id/${diskMain}";
        content = {
          type = "gpt";
          partitions = {
            # Partition 1: EFI (Module looks for -part1)
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = null; # Let zfs-root.boot handle the mount
              };
            };
            # Partition 2: bpool (Module looks for -part2)
            bpool = {
              size = "4G";
              content = {
                type = "zfs";
                pool = "bpool";
              };
            };
            # Partition 3: rpool (Module looks for -part3)
            rpool = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };

      # --- Cache SSD ---
      cache_ssd = {
        type = "disk";
        device = "/dev/disk/by-id/${diskCache}";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "cache";
            };
          };
        };
      };

      # --- Parity & Data HDDs (Mountpoints managed here is fine) ---
      parity1 = {
        type = "disk";
        device = "/dev/disk/by-id/${parityDisk}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/parity1"; extraArgs = [ "-L" "Parity1" ]; };
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
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data1"; extraArgs = [ "-L" "Data1" ]; };
          };
        };
      };
      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 1}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data2"; extraArgs = [ "-L" "Data2" ]; };
          };
        };
      };
      data3 = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt dataDisks 2}";
        content = {
          type = "gpt";
          partitions.primary = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data3"; extraArgs = [ "-L" "Data3" ]; };
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
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data4"; extraArgs = [ "-L" "Data4" ]; };
          };
        };
      };
    };

    zpool = {
      bpool = {
        type = "zpool";
        options.ashift = "12";
        datasets = {
          "nixos" = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/root" = { 
            type = "zfs_fs"; 
            mountpoint = null; # Handled by zfs-root/boot.nix
            options.mountpoint = "legacy"; 
          };
        };
      };
      rpool = {
        type = "zpool";
        options.ashift = "12";
        datasets = {
          "nixos" = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/empty" = { 
            type = "zfs_fs"; 
            mountpoint = null; # Handled by zfs-root/boot.nix
            options.mountpoint = "legacy"; 
          };
          "nixos/home" = { type = "zfs_fs"; mountpoint = null; options.mountpoint = "legacy"; };
          "nixos/nix" = { type = "zfs_fs"; mountpoint = null; options.mountpoint = "legacy"; };
          "nixos/persist" = { type = "zfs_fs"; mountpoint = null; options.mountpoint = "legacy"; };
          "nixos/config" = { type = "zfs_fs"; mountpoint = null; options.mountpoint = "legacy"; };
          "nixos/var" = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/var/log" = { type = "zfs_fs"; mountpoint = null; options.mountpoint = "legacy"; };
          "nixos/var/lib" = { type = "zfs_fs"; mountpoint = null; options.mountpoint = "legacy"; };
        };
      };
      cache = {
        type = "zpool";
        datasets = {
          "data" = { 
            type = "zfs_fs"; 
            mountpoint = null; # Handled by filesystems.nix
            options.mountpoint = "legacy"; 
          };
        };
      };
    };
  };
}