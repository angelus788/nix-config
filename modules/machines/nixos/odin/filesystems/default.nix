{ config
, pkgs
, lib
, ...
}:
let
  hl = config.homelab;
in
{

  imports = [
    ./snapraid.nix
  ];

  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    gptfdisk
    xfsprogs
    parted
    snapraid
    mergerfs
    mergerfs-tools
  ];

  # This fixes the weird mergerfs permissions issue
  boot.initrd.systemd.enable = true;

  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-uuid/63c744e6-5552-47a5-8407-5c620b7958cf";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  fileSystems."/persist" = lib.mkForce {
    device = "/dev/disk/by-uuid/63c744e6-5552-47a5-8407-5c620b7958cf";
    fsType = "btrfs";
    options = [ "subvol=persist" "compress=zstd" "noatime" ];
    neededForBoot = true; # <--- ADD THIS
  };

  fileSystems."/var/log" = lib.mkForce {
    device = "/dev/disk/by-uuid/63c744e6-5552-47a5-8407-5c620b7958cf";
    fsType = "btrfs";
    options = [ "subvol=var_log" "compress=zstd" ];
    neededForBoot = true; # <--- ADD THIS
  };

  fileSystems.${hl.mounts.fast} = lib.mkForce {
    device = "cache";
    fsType = "btrfs";
  };


  fileSystems.${hl.mounts.slow} = lib.mkForce {
    device = "/mnt/data*";
    options = [
      "category.create=mfs"
      "defaults"
      "allow_other"
      "moveonenospc=1"
      "minfreespace=1000G"
      "func.getattr=newest"
      "fsname=mergerfs_slow"
      "uid=994"
      "gid=993"
      "umask=002"
      "x-mount.mkdir"
    ];
    fsType = "fuse.mergerfs";
  };

  fileSystems.${hl.mounts.merged} = lib.mkForce {
    device = "${hl.mounts.fast}:${hl.mounts.slow}";
    options = [
      "category.create=epff"
      "defaults"
      "allow_other"
      "moveonenospc=1"
      "minfreespace=500G"
      "func.getattr=newest"
      "fsname=user"
      "uid=994"
      "gid=993"
      "umask=002"
      "x-mount.mkdir"
    ];
    fsType = "fuse.mergerfs";
  };

  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../6/03) -n standby,q";
    notifications = {
      wall = {
        enable = true;
      };
      mail = {
        enable = true;
        sender = config.email.fromAddress;
        recipient = config.email.toAddress;
      };
    };
  };

}
