{ config, lib, ... }:

with lib;
let
  cfg = config.zfs-root.fileSystems;
in
{
  options.zfs-root.fileSystems = {
    enable = mkEnableOption "ZFS root file systems";
    datasets = mkOption {
      description = "Set mountpoint for datasets";
      type = types.attrsOf types.str;
      default = { };
    };
    efiSystemPartitions = mkOption {
      description = "Set mountpoint for efi system partitions";
      type = types.listOf types.str;
      default = [ ];
    };
    enableDockerZvol = mkOption {
      description = "Enable a separate ext4 zvol for Docker/Podman data";
      type = types.bool;
      default = true;
    };
    bindmounts = mkOption {
      description = "Set mountpoint for bindmounts";
      type = types.attrsOf types.str;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    fileSystems = mkMerge (
      [
        {
          "/" = {
            device = "rpool/nixos/root"; # Changed 'empty' back to 'root' if you want a normal disk
            fsType = "zfs";
            neededForBoot = true;
          };
        }
      ]
      ++ (mapAttrsToList (dataset: mountpoint: {
        "${mountpoint}" = {
          device = "${dataset}";
          fsType = "zfs";
          neededForBoot = true;
        };
      }) cfg.datasets)
      ++ (map (esp: {
        "/boot/efis/${esp}" = {
          device = "${config.zfs-root.boot.devNodes}/${esp}";
          fsType = "vfat";
          options = [
            "x-systemd.idle-timeout=1min"
            "x-systemd.automount"
            "noauto"
            "nofail"
            "noatime"
            "X-mount.mkdir"
          ];
        };
      }) cfg.efiSystemPartitions)
      ++ (mapAttrsToList (bindsrc: mountpoint: {
        "${mountpoint}" = {
          device = "${bindsrc}";
          fsType = "none";
          options = [ "bind" "X-mount.mkdir" "noatime" ];
        };
      }) cfg.bindmounts)
      ++ (optional cfg.enableDockerZvol {
        "/var/lib/containers" = {
          device = "/dev/zvol/rpool/docker";
          fsType = "ext4";
        };
      })
    );
  };
}