let
  diskMain = "ata-CT500MX500SSD1_1947E228A4C0";
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
    };
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
            type = "zfs_fs"; # Changed from zfs_dataset
            options.mountpoint = "none";
          };
          "nixos/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/nixos/root@blank";
          };
          "nixos/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
          "nixos/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          "nixos/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
          };
          "nixos/config" = {
            type = "zfs_fs";
            mountpoint = "/etc/nixos";
          };
          "nixos/var_log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
          };
          "nixos/var_lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
          };
        };
      };
    };
  };
}
