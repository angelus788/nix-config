{ ... }: {

  networking.knownNetworkServices = [
    "Ethernet"
    "Wi-Fi"
    "Thunderbolt Bridge"
  ];

  networking.dns = [
    "100.100.100.100"
    "192.168.1.1"
  ];

  networking.search = [
    "tailcaed2.ts.net"
    "mynetworksettings.com"
  ];

}
