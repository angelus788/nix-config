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

        # `netbird up` is a complete no-op whenever the daemon already
        # reports Connected - it returns immediately, before ever reaching
        # the code that applies flag values like --disable-ssh-auth=false.
        # If this service is ever re-run (its own unit changes, a manual
        # restart, etc.) while the daemon already auto-reconnected from its
        # own saved state, the flags below would silently never re-apply -
        # confirmed live on njord after a series of redeploys left it unable
        # to accept SSH-JWT connections at all. `down` first guarantees `up`
        # actually processes the flags regardless of prior state; `|| true`
        # since `down` on an already-disconnected daemon (a genuinely fresh
        # boot) isn't guaranteed to exit 0.
        ${pkgs.netbird}/bin/netbird down || true
        ${pkgs.netbird}/bin/netbird up \
        --setup-key "$KEY" \
        --management-url https://netbird.avgtechguy.com \
        --allow-server-ssh \
        --disable-ssh-auth=false \
        --disable-dns=false
      '';
    };
  };
}
