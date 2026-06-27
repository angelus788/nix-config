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
  boot.initrd.luks.devices.${cryptroot} = {
    # TODO: Remove this "device" attr if/when machine is reinstalled.
    # This is a workaround for the legacy -> gpt tables disko format.
    device = lib.mkForce "/dev/disk/by-uuid/b085c55b-3cb7-4df2-af8c-d1eec6b03705";
    allowDiscards = true;
    preLVM = true;
    # Add this line to tell systemd-cryptsetup to automatically use the TPM
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  # TODO: Remove this if/when machine is reinstalled.
  # This is a workaround for the legacy -> gpt tables disko format.
  #fileSystems."/boot".device = lib.mkForce "/dev/disk/by-partlabel/ESP";

  disko.devices = {
    disk = {
      # Consolidated single root/boot/data drive. Configured with:
      # - A FAT32 ESP partition for systemd-boot
      # - A LUKS container which contains multiple btrfs subvolumes for nixos install
      nvme0 = {
        device = builtins.elemAt disks 0;
        type = "disk";
        content = {
          type = "gpt";
      partitions = {
          ESP = {
              size = "512M"; # Use 'size' instead of start/end when possible
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%"; # Takes the remaining space automatically
              content = {
                type = "luks";
                name = "${cryptroot}";

                settings = {
                  allowDiscards = true;
                };

                content = {
                  type = "btrfs";
                  # Override existing partition, set filesystem label to match primary mountpoint
                  extraArgs = [ "-f" "-L" "root" ];
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
                    # Migrated from the removed secondary NVMe drive
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