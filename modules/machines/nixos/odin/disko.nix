{ config ? { }, ... }:
let
  bootDrives = config.zfs-root.bootDevices or [
    "ata-CT500MX500SSD1_1947E228A4C0"
    "ata-CT500MX500SSD1_1947E228A5E2"
  ];

  # Mapping the specific IDs to your required labels
  # 4 Data drives + 1 Parity drive
  dataDiskIds = [
    { id = "ata-WDC_WD60EDAZ-11U78B0_WD-WX22A82EZPTC"; label = "Data1"; }
    { id = "ata-WDC_WD60EDAZ-11U78B0_WD-WX52DC0KY6JR"; label = "Data2"; }
    { id = "ata-WDC_WD60EDAZ-11U78B0_WD-WX92D62J3FRL"; label = "Data3"; }
    { id = "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D28H9YHC"; label = "Data4"; }
    { id = "ata-WDC_WD60EFRX-68L0BN1_WD-WX11D57REZ0V"; label = "Parity1"; }
  ];
in
{
  disko.devices = {
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
    # Generate XFS Data Disks
    (builtins.listToAttrs (map (item: {
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
                # Disko will apply the label here
                extraArgs = [ "-L" item.label ];
              };
            };
          };
        };
      };
    }) dataDiskIds));

    zpool.rpool = {
      type = "zpool";
      mode = "mirror";
      rootFsOptions = {
        acltype = "posixacl";
        canmount = "off";
        dnodesize = "auto";
        normalization = "formD";
        relatime = "on";
        xattr = "sa";
        mountpoint = "none";
      };
      datasets = {
        "nixos" = { type = "zfs_fs"; options.mountpoint = "none"; };
        "nixos/root" = { type = "zfs_fs"; mountpoint = "/"; options.mountpoint = "legacy"; postCreateHook = "zfs snapshot rpool/nixos/root@blank"; };
        "nixos/nix" = { type = "zfs_fs"; mountpoint = "/nix"; options.mountpoint = "legacy"; };
        "nixos/persist" = { type = "zfs_fs"; mountpoint = "/persist"; options.mountpoint = "legacy"; };
        "nixos/home" = { type = "zfs_fs"; mountpoint = "/home"; options.mountpoint = "legacy"; };
        "nixos/var_log" = { type = "zfs_fs"; mountpoint = "/var/log"; options.mountpoint = "legacy"; };
        "nixos/var_lib" = { type = "zfs_fs"; mountpoint = "/var/lib"; options.mountpoint = "legacy"; };
      };
    };
  };
}