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
  #
  # Unlike the NixOS apps/netbird module, this does NOT install or start the
  # NetBird system daemon - Home Manager on a non-NixOS host (Ubuntu,
  # SteamOS) has no system-service capability, so the daemon must already be
  # installed via the OS's own package manager (NetBird's official install
  # script: `curl -fsSL https://pkgs.netbird.io/install.sh | sh`), done once
  # manually with root. This unit only issues the login/connect call against
  # that already-running daemon on every HM activation, same pattern as
  # tailscale-hm's `tailscale set --ssh`.
  systemd.user.services.netbird-autoconnect = mkIf isLinux {
    Unit = {
      Description = "Connect NetBird with Setup Key";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      X-Switch-Method = "restart";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "netbird-hm-up" ''
        KEY=$(cat ${config.age.secrets.netbirdSetupKey.path})
        ${pkgs.netbird}/bin/netbird up \
          --setup-key "$KEY" \
          --management-url https://netbird.avgtechguy.com \
          --disable-dns=false
      '';
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Launchd User Agent (darwin)
  # NetBird on macOS requires daemon privileges, but user status commands work via CLI
}
