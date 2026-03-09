{
  disko.devices = {
    disk = {
      # OS Drive (ASRock Boot SSD)
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_1947E228A4C0";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # Maps to the nested path your zfs-root module expects
                mountpoint = "/boot/efis/ata-CT500MX500SSD1_1947E228A4C0-part1";
                mountOptions = [ "umask=0077" ];
              };
            };
            bpool = { size = "4G"; content = { type = "zfs"; pool = "bpool"; }; };
            rpool = { size = "100%"; content = { type = "zfs"; pool = "rpool"; }; };
          };
        };
      };

      # Dedicated Cache Drive
      cache = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_1947E228A5E2";
        content = {
          type = "gpt";
          partitions.zfs = { size = "100%"; content = { type = "zfs"; pool = "cache"; }; };
        };
      };

      # 6TB Data Array (SnapRAID/MergerFS targets)
      data1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX92D62J3FRL";
        content = {
          type = "gpt";
          partitions.content = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data1"; extraArgs = [ "-L" "data1" ]; };
          };
        };
      };
      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EFRX-68L0BN1_WD-WX11D28H9YHC";
        content = {
          type = "gpt";
          partitions.content = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data2"; extraArgs = [ "-L" "data2" ]; };
          };
        };
      };
      data3 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX52DC0KY6JR";
        content = {
          type = "gpt";
          partitions.content = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data3"; extraArgs = [ "-L" "data3" ]; };
          };
        };
      };
      data4 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EDAZ-11U78B0_WD-WX22A82EZPTC";
        content = {
          type = "gpt";
          partitions.content = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data4"; extraArgs = [ "-L" "data4" ]; };
          };
        };
      };
      parity1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD60EFRX-68L0BN1_WD-WX11D57REZ0V";
        content = {
          type = "gpt";
          partitions.content = {
            size = "100%";
            content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/parity1"; extraArgs = [ "-L" "parity1" ]; };
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
          "nixos/root" = { type = "zfs_fs"; mountpoint = "/boot"; options.mountpoint = "legacy"; };
        };
      };
      rpool = {
        type = "zpool";
        options.ashift = "12";
        datasets = {
          "nixos" = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/empty" = { type = "zfs_fs"; mountpoint = "/"; options.mountpoint = "legacy"; };
          "nixos/nix" = { type = "zfs_fs"; mountpoint = "/nix"; options.mountpoint = "legacy"; };
          "nixos/home" = { type = "zfs_fs"; mountpoint = "/home"; options.mountpoint = "legacy"; };
          "nixos/persist" = { type = "zfs_fs"; mountpoint = "/persist"; options.mountpoint = "legacy"; };
          "nixos/config" = { type = "zfs_fs"; mountpoint = "/etc/nixos"; options.mountpoint = "legacy"; };
          "nixos/var/log" = { type = "zfs_fs"; mountpoint = "/var/log"; options.mountpoint = "legacy"; };
          "nixos/var/lib" = { type = "zfs_fs"; mountpoint = "/var/lib"; options.mountpoint = "legacy"; };
        };
      };
      cache = {
        type = "zpool";
        options.ashift = "12";
        datasets = {
          "data" = { type = "zfs_fs"; mountpoint = "/cache"; options.mountpoint = "legacy"; };
        };
      };
    };
  };
}