{ config ? {}, ... }:
let
  # OS Drive
  devices = config.zfs-root.bootDevices or [ "ata-CT500MX500SSD1_1947E228A4C0" ];
  diskMain = builtins.elemAt devices 0;

  # SnapRAID Drives (5.5T each)
  parityDisk = "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D57REZ0V"; # sdc
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
      # --- EXISTING OS DRIVE ---
      main = {
        type = "disk";
        device = "/dev/disk/by-id/${diskMain}";
        content = {
          type = "gpt";
          partitions = {
            efi = { size = "1G"; type = "EF00"; content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot/efis/${diskMain}-part2"; }; };
            bpool = { size = "4G"; content = { type = "zfs"; pool = "bpool"; }; };
            rpool = { end = "-1M"; content = { type = "zfs"; pool = "rpool"; }; };
            bios = { size = "100%"; type = "EF02"; };
          };
        };
      };

      # --- NEW SNAPRAID DRIVES ---
      parity1 = {
        type = "disk";
        device = "/dev/disk/by-id/${parityDisk}";
        content = { type = "gpt"; partitions.zfs = { size = "100%"; content = { type = "zfs"; pool = "p_d1"; }; }; };
      };
      data1 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 0}"; content = { type = "gpt"; partitions.zfs = { size = "100%"; content = { type = "zfs"; pool = "d_d1"; }; }; }; };
      data2 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 1}"; content = { type = "gpt"; partitions.zfs = { size = "100%"; content = { type = "zfs"; pool = "d_d2"; }; }; }; };
      data3 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 2}"; content = { type = "gpt"; partitions.zfs = { size = "100%"; content = { type = "zfs"; pool = "d_d3"; }; }; }; };
      data4 = { type = "disk"; device = "/dev/disk/by-id/${builtins.elemAt dataDisks 3}"; content = { type = "gpt"; partitions.zfs = { size = "100%"; content = { type = "zfs"; pool = "d_d4"; }; }; }; };
    };

    zpool = {
      # bpool and rpool configurations remain as they were in your snippet
      bpool = {
        type = "zpool";
        options = { ashift = "12"; autotrim = "on"; compatibility = "grub2"; };
        mountpoint = "/boot";
        datasets = {
          nixos = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/root" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/boot"; };
        };
      };

      rpool = {
        type = "zpool";
        options = { ashift = "12"; autotrim = "on"; };
        mountpoint = "/";
        datasets = {
          nixos = { type = "zfs_fs"; options.mountpoint = "none"; };
          "nixos/empty" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/"; postCreateHook = "zfs snapshot rpool/nixos/empty@start"; };
          "nixos/home" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/home"; };
          "nixos/data" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/mnt/user"; };
          "nixos/var/log" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/var/log"; };
          "nixos/var/lib" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/var/lib"; };
          "nixos/config" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/etc/nixos"; };
          "nixos/persist" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/persist"; };
          "nixos/nix" = { type = "zfs_fs"; options.mountpoint = "legacy"; mountpoint = "/nix"; };
        };
      };

      # New SnapRAID Pools
      p_d1 = { type = "zpool"; mountpoint = "/mnt/parity1"; datasets.storage = { type = "zfs_dataset"; mountpoint = "/mnt/parity1/storage"; }; };
      d_d1 = { type = "zpool"; mountpoint = "/mnt/data1";   datasets.storage = { type = "zfs_dataset"; mountpoint = "/mnt/data1/storage"; }; };
      d_d2 = { type = "zpool"; mountpoint = "/mnt/data2";   datasets.storage = { type = "zfs_dataset"; mountpoint = "/mnt/data2/storage"; }; };
      d_d3 = { type = "zpool"; mountpoint = "/mnt/data3";   datasets.storage = { type = "zfs_dataset"; mountpoint = "/mnt/data3/storage"; }; };
      d_d4 = { type = "zpool"; mountpoint = "/mnt/data4";   datasets.storage = { type = "zfs_dataset"; mountpoint = "/mnt/data4/storage"; }; };
    };
  };
}