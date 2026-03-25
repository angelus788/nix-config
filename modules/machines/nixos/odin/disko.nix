{ config ? { }, ... }:
let
  bootDrives = [
    "ata-CT500MX500SSD1_1947E228A4C0"
  ];

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
    disk = (builtins.listToAttrs (builtins.genList
      (i: {
        name = "boot${toString i}";
        value = {
          type = "disk";
          device = "/dev/disk/by-id/${builtins.elemAt bootDrives i}";
          content = {
            type = "gpt";
            partitions = {
              boot = { size = "1M"; type = "EF02"; }; # BIOS compatibility
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot"; # Simplified mountpoint for Btrfs setup
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist/ssh" = {
                      mountpoint = "/persist/ssh";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/var_log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      })
      (builtins.length bootDrives))) //

    # Generate XFS Data Disks (Remains Unchanged)
    (builtins.listToAttrs (map
      (item: {
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
                  mountpoint = "/mnt/${item.label}";
                };
              };
            };
          };
        };
      })
      dataDiskIds));
  };
}
