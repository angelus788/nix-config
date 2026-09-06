{ ... }:

{
  disko.devices = {

    ####################################
    # Root + home disk (nvme0n1)
    ####################################
    disk.nvme0n1 = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-WDS100T1XHE-00AFY0_21411T802058";

      content = {
        type = "gpt";

        partitions = {

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

          root = {
            size = "150G";

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };

          persist = {
            size = "10G";

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist";
            };
          };

          home = {
            size = "100%";

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
            };
          };

        };
      };
    };

    ####################################
    # Data disks
    ####################################

    disk.sda = {
      type = "disk";
      device = "/dev/disk/by-id/ata-CT500MX500SSD1_1948E22B100C";

      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/data/sda";
          };
        };
      };
    };

    disk.sdb = {
      type = "disk";
      device = "/dev/disk/by-id/ata-CT500MX500SSD1_1948E22B1062";

      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/data/sdb";
          };
        };
      };
    };

  };
}
