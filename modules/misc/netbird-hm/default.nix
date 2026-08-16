{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  home.packages = [ pkgs.netbird ];

  # Systemd User Service (Linux / Steam Deck)
  config = mkIf isLinux {
    systemd.user.services.netbird-autoconnect = {
      Unit = {
        Description = "Ensure NetBird connection state";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        X-Switch-Method = "restart";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.netbird}/bin/netbird up";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  # Launchd User Agent (darwin)
  # NetBird on macOS requires daemon privileges, but user status commands work via CLI
}
