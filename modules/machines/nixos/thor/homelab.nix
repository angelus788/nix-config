{ config, ... }:
{
  # Reachable directly at http://100.84.83.10:9119 over the NetBird overlay
  # (see the hermes-agent module) with basic auth configured, since it
  # refuses non-loopback binds without an auth provider and rejects
  # mismatched Host headers. Bound to thor's NetBird IP directly rather than
  # thor.thorsaga.net, since split-DNS resolution of that name has proven
  # unreliable. No TLS termination needed here — the wt0 interface is
  # already trusted by the firewall and WireGuard encrypts the transport.
  homelab.services.hermes-agent = {
    enable = true;
    url = "100.84.83.10";
    dashboardAuthEnvironmentFile = config.age.secrets.hermesDashboardAuth.path;
  };
}
