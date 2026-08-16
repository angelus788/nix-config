{
  config,
  pkgs,
  inputs,
  ...
}:
let
  targetUser = "angelus";
in
{
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.tailscale = {
    package = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.tailscale;
    enable = true;
    authKeyFile = config.age.secrets.tailscaleAuthKey.path;
    extraUpFlags = [
      "--accept-routes"
      "--ssh"
    ];
  };

  # Force Tailscale flags to re-apply after tailscaled starts
  systemd.services.tailscaled.serviceConfig.ExecStartPost = [
    "${pkgs.tailscale}/bin/tailscale set --accept-routes --ssh --operator=${targetUser}"
  ];
}
