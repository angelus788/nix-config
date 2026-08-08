{
  lib,
  disks ? [
    "/dev/nvme0n1"
  ],
  ...
}:
let
  cryptroot = "cryptroot";
  defaultBtrfsOpts = [
    "defaults"
    "compress=zstd:1"
    "ssd"
    "noatime"
    "nodiratime"
  ];
in
{
  disko.devices = {
    disk = {
      nvme0 = {
        device = builtins.elemAt disks 0;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # 1GB ESP partition configured for systemd-boot / Lanzaboote
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
            # Dedicated 4GB Swap partition matching your lsblk output
            swap = {
              size = "4G";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };
            # Remaining disk space allocated to LUKS and Btrfs subvolumes
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "${cryptroot}";

                settings = {
                  allowDiscards = true;
                  crypttabExtraOpts = [ "tpm2-device=auto" ];
                };

                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f"
                    "-L"
                    "root"
                  ];
                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      mountOptions = defaultBtrfsOpts;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = defaultBtrfsOpts;
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = defaultBtrfsOpts;
                    };
                    "@var" = {
                      mountpoint = "/var";
                      mountOptions = defaultBtrfsOpts;
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = defaultBtrfsOpts;
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = defaultBtrfsOpts;
                    };
                    "@data" = {
                      mountpoint = "/home/angelus/data";
                      mountOptions = defaultBtrfsOpts;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
