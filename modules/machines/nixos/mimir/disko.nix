{ config ? { }, ... }:
let
  # Selecting the larger NVMe drive as the primary
  # nvme-CT500P1SSD8_1937E21ED6C8
  device = config.zfs-root.bootDevice or "nvme-CT500P1SSD8_1937E21ED6C8";
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/${device}";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # BIOS boot
            };
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
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
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };
    zpool = {
      bpool = {
        type = "zpool";
        # Mode removed (defaults to single disk)
        options = {
          ashift = "12";
          autotrim = "on";
          compatibility = "grub2";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "lz4";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
        };
        datasets = {
          "nixos" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/boot";
          };
        };
      };
      rpool = {
        type = "zpool";
        # Mode removed
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "zstd";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
        };
        datasets = {
          "nixos" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/empty" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/nixos/empty@start";
          };
          "nixos/home" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/home"; };
          "nixos/var" = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/var/log" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/var/log"; };
          "nixos/var/lib" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/var/lib"; };
          "nixos/nix" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/nix"; };
          "nixos/persist" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/persist"; };
          "docker" = {
            type = "zfs_volume";
            size = "50G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var/lib/containers";
            };
          };
        };
      };
    };
  };
}
