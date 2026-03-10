{ config, builtins, ... }:
let
  # Grab the single boot device from your config
  diskMain = builtins.elemAt config.zfs-root.bootDevices 0;

  # WD Red IDs for the Data Array
  dataDisks = [
    "ata-WDC_WD60EFRX-68L0BN1_WD-WXH1H84H1N1Z" # data1
    "ata-WDC_WD60EFRX-68L0BN1_WD-WXH1H84H2L1Z" # data2
    "ata-WDC_WD60EFRX-68L0BN1_WD-WXH1H84H3K1Z" # data3
    "ata-WDC_WD60EFRX-68L0BN1_WD-WXH1H84H4J1Z" # data4
    "ata-WDC_WD60EFRX-68L0BN1_WD-WXH1H84H5H1Z" # parity1
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
              size = "1M";
              type = "EF02"; # For GRUB MBR compatibility if needed
            };
          };
        };
      };

      # Data Disks Mapping
      data1 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 0}"; content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data1"; }; }; }; }; };
      data2 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 1}"; content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data2"; }; }; }; }; };
      data3 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 2}"; content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data3"; }; }; }; }; };
      data4 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 4}"; content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/data4"; }; }; }; }; };
      parity1 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 4}"; content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "xfs"; mountpoint = "/mnt/parity1"; }; }; }; }; };
    };

    zpool = {
      bpool = {
        type = "zpool";
        options = { ashift = "12"; autotrim = "on"; compatibility = "grub2"; };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "lz4";
          normalization = "formD";
          xattr = "sa";
        };
        mountpoint = "/boot";
        datasets = {
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
          canmount = "off";
          compression = "zstd";
          dnodesize = "auto";
          normalization = "formD";
          xattr = "sa";
        };
        mountpoint = "/";
        datasets = {
          "nixos/empty" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/nixos/empty@start";
          };
          "nixos/home" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/home"; };
          "nixos/var/log" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/var/log"; };
          "nixos/var/lib" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/var/lib"; };
          "nixos/config" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/etc/nixos"; };
          "nixos/persist" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/persist"; };
          "nixos/nix" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/nix"; };
        };
      };
    };
  };
}