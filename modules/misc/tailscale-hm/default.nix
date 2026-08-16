{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  config = mkIf isLinux {
    systemd.user.services.tailscale-autoconnect = {
      Unit = {
        Description = "Ensure Tailscale SSH is enabled";
        After = [ "network.target" ];
        X-Switch-Method = "restart";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.tailscale}/bin/tailscale set --ssh";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
