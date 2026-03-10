{ config, ... }:
let
  diskMain = builtins.head config.zfs-root.bootDevices;
in
{
  disko.devices = {
    disk.main = {
      type = "disk"; # Added type: "disk" here
      device = "/dev/disk/by-id/${diskMain}";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";
          };
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
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };
    # Moved zpool INSIDE disko.devices
    zpool = {
      rpool = {
        type = "zpool";
        rootFsOptions = {
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          mountpoint = "none";
          canmount = "off";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          "nixos" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy"; # Best practice for ephemeral roots
            postCreateHook = "zfs snapshot rpool/nixos/root@blank";
          };
          "nixos/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          "nixos/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
          "nixos/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options.mountpoint = "legacy";
          };
          "nixos/config" = {
            type = "zfs_fs";
            mountpoint = "/etc/nixos";
            options.mountpoint = "legacy";
          };
          "nixos/var_log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options.mountpoint = "legacy";
          };
          "nixos/var_lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  }; # End of disko.devices
}
