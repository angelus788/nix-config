{ pkgs, config, lib, ... }:
let
  isLinux = !pkgs.stdenv.hostPlatform.isDarwin;
in
{
  config = lib.mkIf isLinux {
    # 1. Install dependencies if not Darwin Platform
    home.packages = with pkgs; [
      tailscale # The official client now includes 'tailscale systray'
      wl-clipboard # Required for copying IPs to clipboard (use xclip for X11)
    ];

    # 2. Define the official systray as a systemd user service
    systemd.user.services.tailscale-systray = {
      Unit = {
        Description = "Official Tailscale System Tray";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        # Runs the official 'tailscale systray' command
        ExecStart = "${pkgs.tailscale}/bin/tailscale systray";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
