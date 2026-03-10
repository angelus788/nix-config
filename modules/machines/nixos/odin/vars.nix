{ lib, ... }: {
  options.zfs-root.bootDevices = lib.mkOption {
    type = lib.types.listOf lib.types.str;
  };

  config.zfs-root.bootDevices = [ "ata-CT500MX500SSD1_1947E228A4C0" ];
}
