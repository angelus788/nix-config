{
  config,
  pkgs,
  ...
}:
{
  # Enable NetBird daemon service
  services.netbird.enable = true;

  # Firewall exceptions
  networking.firewall.trustedInterfaces = [ "wt0" ]; # NetBird uses 'wt0' interface

  # Auto-connect service using Agenix setup key
  systemd.services.netbird-autoconnect = {
    description = "Connect NetBird with Setup Key";
    after = [
      "network-online.target"
      "netbird.service"
    ];
    wants = [
      "network-online.target"
      "netbird.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "netbird-up" ''
        KEY=$(cat ${config.age.secrets.netbirdSetupKey.path})
        ${pkgs.netbird}/bin/netbird up \
        --setup-key "$KEY" \
        --management-url https://netbird.avgtechguy.com \
        --allow-server-ssh \
        --disable-ssh-auth \
        --disable-dns=false
      '';
    };
  };
}
