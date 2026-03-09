{ config, ... }:
let
  # Dynamically pulls the first boot disk from your zfs-root module
  diskMain = builtins.head config.zfs-root.bootDevices;
in
{
  disko.devices = {
    disk = {
      # OS Drive - Dynamic based on zfs-root configuration
      main = {
        type = "disk";
        device = "/dev/disk/by-id/${diskMain}";
        content = {
          type = "gpt";
          partitions = {
            efi = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # Correctly maps to the nested path for your zfs-root logic
                mountpoint = "/boot/efis/${diskMain}-part2";
              };
            };
            bpool = {
              size = "4G";
              content = {
                type = "zfs";
                pool = "bpool";
              };
            };
            rpool = {
              end = "-1M";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
            bios = {
              size = "100%";
              type = "EF02"; # Partition for BIOS boot compatibility
            };
          };
        };
      };

      # Dedicated Cache Drive (Odin SSD)
      cache = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_1947E228A5E2";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = { type = "zfs"; pool = "cache"; };
          };
        };
      };

      # Odin 6TB Data Array (SnapRAID/MergerFS)
      # Using a list to keep the data drive definitions clean
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
        options = { ashift = "12"; autotrim = "on"; compatibility = "grub2"; };
        rootFsOptions = {
          acltype = "posixacl";
          compression = "lz4";
          devices = "off";
          xattr = "sa";
        };
        datasets = {
          "nixos" = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/boot";
          };
        };
      };

      rpool = {
        type = "zpool";
        options = { ashift = "12"; autotrim = "on"; };
        rootFsOptions = {
          acltype = "posixacl";
          compression = "zstd";
          dnodesize = "auto";
          xattr = "sa";
        };
        datasets = {
          "nixos" = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/empty" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            # Automates your Step 5!
            postCreateHook = "zfs snapshot rpool/nixos/empty@start";
          };
          "nixos/home" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/home"; };
          "nixos/persist" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/persist"; };
          "nixos/nix" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/nix"; };
          "nixos/config" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/etc/nixos"; };
          "nixos/var/log" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/var/log"; };
          "nixos/var/lib" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/var/lib"; };
          "docker" = {
            type = "zfs_volume";
            size = "50G";
            content = { type = "filesystem"; format = "ext4"; mountpoint = "/var/lib/containers"; };
          };
        };
      };

      cache = {
        type = "zpool";
        options.ashift = "12";
        datasets = {
          "data" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/cache"; };
        };
      };
    };
  };
}