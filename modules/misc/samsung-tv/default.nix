{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.samsungtv;

  # Create a Python environment with the Samsung TV library
  samsungPython = pkgs.python3.withPackages (ps: [
    ps.samsungtvws
    ps.wakeonlan
  ]);

  # Helper to run the Python commands
  # Note: The first run requires manual 'Allow' on the TV screen
  samsung-ctl = pkgs.writeShellScriptBin "samsung-ctl" ''
    ${samsungPython}/bin/python3 -c "
import sys
from samsungtvws import SamsungTVWS
from wakeonlan import send_magic_packet

tv = SamsungTVWS('${cfg.ipAddress}')

if sys.argv[1] == 'on':
    send_magic_packet('${cfg.macAddress}')
    # Power on usually takes a few seconds before the WS API responds
elif sys.argv[1] == 'off':
    tv.shortcuts().power()
elif sys.argv[1] == 'input':
    tv.shortcuts().set_source('${cfg.hdmiInput}')
" "$1"
  '';

  tv-on = pkgs.writeShellScriptBin "tv-on" ''
    echo "Sending Wake-on-LAN..."
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
    echo "Failed to switch input after 15 tries."
    exit 1
  '';

  tv-off = pkgs.writeShellScriptBin "tv-off" ''
    ${samsung-ctl}/bin/samsung-ctl off
  '';
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
      default = "HDMI"; # Usually "HDMI", "HDMI1", etc.
      description = "The HDMI source name";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wol
      samsung-ctl
      tv-on
      tv-off
    ];

    # Automation: Run on sleep/wake
    powerManagement.resumeCommands = "${tv-on}/bin/tv-on";
    powerManagement.powerDownCommands = "${tv-off}/bin/tv-off";

    # Optional Systemd service to ensure it runs on boot
    systemd.services.samsungtv-on = {
      description = "Turn on Samsung TV and set input";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "angelus"; # Or your specific user
      };
      script = "${tv-on}/bin/tv-on";
    };
  };
}