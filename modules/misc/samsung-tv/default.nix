{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.samsungtv;

  samsungPython = pkgs.python3.withPackages (ps: [
    ps.samsungtvws
    ps.wakeonlan
  ]);

  samsung-ctl = pkgs.writeShellScriptBin "samsung-ctl" ''
    ${samsungPython}/bin/python3 -c "
import sys
from samsungtvws import SamsungTVWS
from wakeonlan import send_magic_packet

tv = SamsungTVWS('${cfg.ipAddress}')

if sys.argv[1] == 'on':
    send_magic_packet('${cfg.macAddress}')
elif sys.argv[1] == 'off':
    tv.shortcuts().power()
elif sys.argv[1] == 'input':
    tv.shortcuts().set_source('${cfg.hdmiInput}')
" "$1"
  '';

  tv-on = pkgs.writeShellScriptBin "tv-on" ''
    echo "Sending Wake-on-LAN to ${cfg.macAddress}..."
    ${pkgs.wol}/bin/wol ${cfg.macAddress}
    
    count=0
    while [ $count -lt 15 ]; do
      echo "Attempting to set input to ${cfg.hdmiInput} (Try $count)..."
      if ${samsung-ctl}/bin/samsung-ctl input; then
        echo "Success!"
        exit 0
      fi
      sleep 2
      count=$((count + 1))
    done
    exit 1
  '';

  tv-off = pkgs.writeShellScriptBin "tv-off" ''
    ${samsung-ctl}/bin/samsung-ctl off
  '' ;
in
{
  options.services.samsungtv = {
    enable = lib.mkEnableOption "Samsung TV integration";
    ipAddress = lib.mkOption {
      type = lib.types.str;
      description = "IP address of the Samsung TV";
    };
    macAddress = lib.mkOption {
      type = lib.types.str;
      description = "MAC address for Wake-on-LAN";
    };
    hdmiInput = lib.mkOption {
      type = lib.types.str;
      default = "HDMI";
      description = "The HDMI source name";
    };
    # Added these back to satisfy your configuration.nix
    user = lib.mkOption {
      type = lib.types.str;
      description = "User to run the commands as";
      default = "root";
    };
    group = lib.mkOption {
      type = lib.types.str;
      description = "Group to run the commands as";
      default = "wheel";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wol
      samsung-ctl
      tv-on
      tv-off
    ];

    powerManagement.resumeCommands = "${tv-on}/bin/tv-on";
    powerManagement.powerDownCommands = "${tv-off}/bin/tv-off";

    systemd.services.samsungtv-on = {
      description = "Turn on Samsung TV and set input";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;  # Now uses the option you defined
        Group = cfg.group; # Now uses the option you defined
      };
      script = "${tv-on}/bin/tv-on";
    };
  };
}