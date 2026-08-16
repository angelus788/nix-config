{
  config,
  lib,
  ...
}:
{
  systemd.user.services.tailscale-autoconnect = {
    Unit = {
      Description = "Ensure Tailscale SSH is enabled";
      After = [ "network.target" ];
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
}
