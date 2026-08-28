{ config, ... }:
{
  # Reachable directly at http://thor.thorsaga.net:9119 over the NetBird
  # overlay (see the hermes-agent module) with basic auth configured, since
  # it refuses non-loopback binds without an auth provider and rejects
  # mismatched Host headers. No TLS termination needed here — the wt0
  # interface is already trusted by the firewall and WireGuard encrypts
  # the transport.
  homelab.services.hermes-agent = {
    enable = true;
    dashboardAuthEnvironmentFile = config.age.secrets.hermesDashboardAuth.path;
  };
}
