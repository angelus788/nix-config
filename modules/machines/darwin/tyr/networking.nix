{ ... }: {

  networking.knownNetworkServices = [
    "Ethernet"
    "Wi-Fi"
    "Thunderbolt Bridge"
  ];

  # 100.100.100.100 was Tailscale's MagicDNS stub resolver; now that this
  # host is on NetBird, that address answers nothing and was silently
  # eating DNS queries that fell through to it before the router's.
  # NetBird injects its own split-DNS resolver for thorsaga.net (and
  # thorsaga.net's search domain) dynamically via scutil - it doesn't need
  # to be listed here.
  networking.dns = [
    "192.168.1.1"
  ];

  networking.search = [
    "mynetworksettings.com"
  ];

}
