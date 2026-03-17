{ config, ... }:
let
  # OS Drives (Crucial SSDs)
  bootDrives = [
    "ata-CT500MX500SSD1_1947E228A4C0"
    "ata-CT500MX500SSD1_1947E228A5E2"
  ];

  # Storage Drives (WD 6TB)
  storageDrives = [
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX22A82EZPTC"
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX52DC0KY6JR"
    "ata-WDC_WD60EDAZ-11U78B0_WD-WX92D62J3FRL"
    "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D28H9YHC"
    "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D57REZ0V"
  ];
in
{
  disko.devices = {
    # Generate Boot Disk configurations
    disk = (builtins.listToAttrs (builtins.genList (i: {
      name = "boot${toString i}";
      value = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt bootDrives i}";
        content = {
          type = "gpt";
          partitions = {
            boot = { size = "1M"; type = "EF02"; };
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efis/boot${toString i}";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = { type = "zfs"; pool = "rpool"; };
            };
          };
        };
      };
    }) (builtins.length bootDrives))) // 
    # Generate Storage Disk configurations
    (builtins.listToAttrs (builtins.genList (i: {
      name = "storage${toString i}";
      value = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.elemAt storageDrives i}";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = { type = "zfs"; pool = "dpool"; };
            };
          };
        };
      };
    }) (builtins.length storageDrives)));

    zpool = {
      rpool = {
        type = "zpool";
        mode = "mirror";
        options = { ashift = "12"; autotrim = "on"; };
        rootFsOptions = {
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          mountpoint = "none";
          canmount = "off";
        };
        datasets = {
          "nixos" = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
            postCreateHook = "zfs snapshot rpool/nixos/root@blank";
          };
          "nixos/nix" = { type = "zfs_fs"; mountpoint = "/nix"; options.mountpoint = "legacy"; };
          "nixos/home" = { type = "zfs_fs"; mountpoint = "/home"; options.mountpoint = "legacy"; };
          "nixos/persist" = { type = "zfs_fs"; mountpoint = "/persist"; options.mountpoint = "legacy"; };
          "nixos/var_log" = { type = "zfs_fs"; mountpoint = "/var/log"; options.mountpoint = "legacy"; };
          "nixos/var_lib" = { type = "zfs_fs"; mountpoint = "/var/lib"; options.mountpoint = "legacy"; };
        };
      };

      dpool = {
        type = "zpool";
        mode = "raidz"; # Single parity for 5 drives
        options = { ashift = "12"; autotrim = "on"; };
        rootFsOptions = {
          compression = "zstd";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          mountpoint = "none";
        };
        datasets = {
          "data" = {
            type = "zfs_fs";
            mountpoint = "/data";
            options.mountpoint = "legacy";
          };
          "media" = {
            type = "zfs_fs";
            mountpoint = "/data/media";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}