{
  config,
  lib,
  ...
}:
{

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.tailscaleAuthKey.path;
    # Required for subnet-router/exit-node forwarding (enables IP forwarding).
    useRoutingFeatures = "server";
    extraUpFlags =
      let
        isExternal = lib.attrsets.hasAttrByPath [ config.networking.hostName ] config.homelab.networks.external;
        advertisedRoute =
          if isExternal then
            "${config.homelab.networks.external.${config.networking.hostName}.v4.address}/32"
          else
            # homelab.networks.local.lan.cidr.v4 is stale (192.168.2.1, doesn't
            # match the actual 192.168.1.0/24 range hosts/reservations live on),
            # so the real LAN subnet is hardcoded here rather than trusted.
            "192.168.1.0/24";
      in
      [
        "--advertise-routes=${advertisedRoute}"
      ]
      ++ lib.optional (!isExternal) "--advertise-exit-node"
      ++ [ "--reset" ];
  };
}
