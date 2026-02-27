{ config
, pkgs
, lib
, inputs
, ...
}:
let
  # Define the target username here
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

  systemd.services.tailscale-operator = {
    description = "Grant Tailscale operator permissions";
    after = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      # Dynamically use the variable
      ExecStart = "${pkgs.tailscale}/bin/tailscale set --operator=${targetUser}";
      RemainAfterExit = true;
    };
  };
}
