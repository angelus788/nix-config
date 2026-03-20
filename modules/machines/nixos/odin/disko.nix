{ config, ... }:
let
  diskMain = builtins.head config.zfs-root.bootDevices;
  dataDiskIds = [
    { id = "ata-WDC_WD60EDAZ-11U78B0_WD-WX22A82EZPTC"; label = "Data1"; }
    { id = "ata-WDC_WD60EDAZ-11U78B0_WD-WX52DC0KY6JR"; label = "Data2"; }
    { id = "ata-WDC_WD60EDAZ-11U78B0_WD-WX92D62J3FRL"; label = "Data3"; }
    { id = "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D28H9YHC"; label = "Data4"; }
    { id = "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D57REZ0V"; label = "Parity1"; }
  ];

  # Helper to generate the data disk set
  dataDisks = builtins.listToAttrs (map (item: {
    name = item.label;
    value = {
      type = "disk";
      device = "/dev/disk/by-id/${item.id}";
      content = {
        type = "gpt";
        partitions = {
          primary = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              extraArgs = [ "-L" item.label ];
              # Ensure they mount so SnapRAID/MergerFS can find them
              mountpoint = "/mnt/${item.label}";
            };
          };
        };
      };
    };
  }) dataDiskIds);
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
            efi = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
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
              type = "EF02";
            };
          };
        };
      };
    } // dataDisks; # Merges the data disks into the main disk set

    zpool = {
      bpool = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
          compatibility = "grub2";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "lz4";
          devices = "off";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/boot";
        datasets = {
          nixos = {
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
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/";

        datasets = {
          nixos = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/var" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/empty" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/nixos/empty@start";
          };
          "nixos/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };
          "nixos/data" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/user";
          };
          "nixos/var/log" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/log";
          };
          "nixos/var/lib" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib";
          };
          "nixos/config" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/etc/nixos";
          };
          "nixos/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
          };
          "nixos/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
          docker = {
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