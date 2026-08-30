{ ... }: {

  networking.knownNetworkServices = [
    "Ethernet"
    "Wi-Fi"
    "Thunderbolt Bridge"
  ];

  # 100.100.100.100 was Tailscale's MagicDNS stub resolver; now that this
  # host is on NetBird, that address answers nothing and was silently
  # eating DNS queries that fell through to it before the router's.
  # NetBird injects its own split-DNS resolver for thorsaga.net dynamically
  # via scutil - it doesn't need to be listed here.
  networking.dns = [
    "192.168.1.1"
  ];

  # NetBird registers thorsaga.net as a routing-only match domain, not a
  # search domain, so unqualified peer names (e.g. `ping heimdall`) never
  # get `.thorsaga.net` appended on their own. Listed explicitly here so bare
  # hostnames resolve, matching the fleet-wide NixOS `networking.search` entry.
  networking.search = [
    "mynetworksettings.com"
    "thorsaga.net"
  ];

}
