{ config, lib, ... }:

{
  disko.devices = {

    ####################################
    # Root disk (nvme1n1)
    ####################################
    disk.nvme1n1 = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-CT500P1SSD8_1937E21F3758";

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
            size = "100%";

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };

        };
      };
    };

    ####################################
    # Home disk (nvme0n1)
    ####################################
    disk.nvme0n1 = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_HS_2000GB_24054Y800036";

      content = {
        type = "gpt";

        partitions = {
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
      device = "/dev/disk/by-id/ata-WDC_WD2003FZEX-00SRLA0_WD-WCC6NLCYUSU8";

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
      device = "/dev/disk/by-id/ata-ST4000DM004-2U9104_ZFN5JXMM";

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

    disk.sdc = {
      type = "disk";
      device = "/dev/disk/by-id/ata-CT500MX500SSD1_1947E228A4A1";

      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/data/sdc";
          };
        };
      };
    };

  };
}
