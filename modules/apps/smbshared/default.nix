{ config, pkgs, ... }: {

  # Dynamically generate the mounts
  fileSystems = (builtins.listToAttrs (map (share: {
    name = "/mnt/odin/${share}";
    value = {
      device = "//odin/${share}"; 
      fsType = "cifs";
      options = [
        "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s"
        
        # Pulls the decrypted path dynamically from agenix
        "credentials=${config.age.secrets.smbshared.path}"
        
        "uid=1000" 
        "gid=100"
        "file_mode=0664"
        "dir_mode=0775"
      ];
    };
  }) [
    "Backups"
    "Documents"
    "Media"
    "Music"
    "Misc"
    "TimeMachine"
    "YoutubeArchive"
    "YoutubeCurrent"
  ]));

}