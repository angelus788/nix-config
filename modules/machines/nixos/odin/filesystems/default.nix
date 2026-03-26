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

  fileSystems.${hl.mounts.fast} = lib.mkForce {
    device = "/dev/disk/by-label/cache";
    fsType = "btrfs";
    options = [ "subvol=cache" "noatime" "compress=zstd" ];
  };

  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/odin-root";
    fsType = "btrfs";
    options = [ "subvol=root" ];
  };

  fileSystems."/Data1" = lib.mkForce {
    device = "/dev/disk/by-label/data1";
    fsType = "xfs";
  };

  fileSystems."/Data2" = lib.mkForce {
    device = "/dev/disk/by-label/data2";
    fsType = "xfs";
  };

  fileSystems."/Data3" = lib.mkForce {
    device = "/dev/disk/by-label/data3";
    fsType = "xfs";
  };

  fileSystems."/Data4" = lib.mkForce {
    device = "/dev/disk/by-label/data4";
    fsType = "xfs";
  };

  fileSystems."/Parity1" = lib.mkForce {
    device = "/dev/disk/by-label/parity1";
    fsType = "xfs";
  };

  fileSystems."/boot" = lib.mkForce {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
    neededForBoot = true;
  };


  fileSystems."/home" = lib.mkForce {
    device = "/dev/disk/by-label/odin-root";
    fsType = "btrfs";
    options = [ "subvol=home" ];
  };

  fileSystems."/nix" = lib.mkForce {
    device = "/dev/disk/by-label/odin-root";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
    neededForBoot = true;
  };

  fileSystems."/persist" = lib.mkForce {
    device = "/dev/disk/by-label/odin-root";
    fsType = "btrfs";
    options = [ "subvol=persist" ];
    neededForBoot = true;
  };

  fileSystems."/var/log" = lib.mkForce {
    device = "/dev/disk/by-label/odin-root";
    fsType = "btrfs";
    options = [ "subvol=var_log" ];
    neededForBoot = true;
  };

  fileSystems.${hl.mounts.slow} = lib.mkForce {
    device = "/Data*";
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
