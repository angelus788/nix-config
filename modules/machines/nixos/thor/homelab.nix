{ config, pkgs, ... }:
{
  homelab.services.hermes-agent = {
    enable = true;
    dashboardAuthEnvironmentFile = config.age.secrets.hermesDashboardAuth.path;
  };

  # Publishes the Hermes dashboard over the tailnet with a real Tailscale-issued
  # cert. Hermes itself binds directly to the Tailscale MagicDNS name (see the
  # hermes-agent module) with basic auth configured, since it refuses non-loopback
  # binds without an auth provider and rejects mismatched Host headers.
  systemd.services.tailscale-serve-hermes = {
    description = "tailscale serve for the Hermes dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [
      "tailscaled.service"
      "hermes-backend.service"
    ];
    wants = [
      "tailscaled.service"
      "hermes-backend.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https=443 http://${config.homelab.services.hermes-agent.url}:${toString config.services.hermes-agent.backend.port}";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=443 off";
    };
  };
}
