{
  config,
  pkgs,
  lib,
  ...
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

   fileSystems."/" =
    { device = "tmpfs";
      fsType = lib.mkForce "tmpfs";
    };

  fileSystems."/mnt/boot" = {
    device = "/dev/disk/by-uuid/62EB-3349";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  fileSystems.${hl.mounts.fast} = lib.mkForce {
    device = "cache";
    fsType = "btrfs";
  };

  fileSystems."/mnt/data1" = lib.mkForce {
    device = "/dev/disk/by-label/Data1";
    fsType = "xfs";
  };

  fileSystems."/mnt/data2" = lib.mkForce {
    device = "/dev/disk/by-label/Data2";
    fsType = "xfs";
  };

  fileSystems."/mnt/data3" = lib.mkForce {
    device = "/dev/disk/by-label/Data3";
    fsType = "xfs";
  };
  
  fileSystems."/mnt/data4" = lib.mkForce  {
    device = "/dev/disk/by-label/Data4";
    fsType = "xfs";
  };

  fileSystems."/mnt/parity1" = lib.mkForce  {
    device = "/dev/disk/by-label/Parity1";
    fsType = "xfs";
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
