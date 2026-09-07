{
  pkgs,
  config,
  lib,
  ...
}:
let
  homelab = config.homelab;
  cfg = homelab.services.wireguard-netns;
in
{
  options.homelab.services.wireguard-netns = {
    enable = lib.mkEnableOption {
      description = "Enable Wireguard client network namespace";
    };
    namespace = lib.mkOption {
      type = lib.types.str;
      description = "Network namespace to be created";
      default = "wg_client";
    };
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Services to restart when the tunnel's WireGuard handshake goes stale (in addition to the tunnel itself)";
      default = [
        cfg.namespace
      ];
    };
    healthcheck = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Periodically verify the tunnel has a live WireGuard handshake and recover it (and monitoredServices) if it doesn't";
      };
      staleAfterSec = lib.mkOption {
        type = lib.types.int;
        default = 300;
        description = "How old the newest handshake may be before the tunnel is considered dead";
      };
      intervalSec = lib.mkOption {
        type = lib.types.int;
        default = 180;
        description = "How often to run the handshake check";
      };
    };
    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file with Wireguard config (not a wg-quick one!)";
      example = lib.literalExpression ''
        pkgs.writeText "wg0.conf" '''
          [Interface]
          PrivateKey = <client's privatekey>

          [Peer]
          PublicKey = <server's publickey>
          Endpoint = <server's ip>:51820
        '''
      '';
    };
    privateIP = lib.mkOption {
      type = lib.types.str;
    };
    dnsIP = lib.mkOption {
      type = lib.types.str;
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services."netns@" = {
      description = "%I network namespace";
      before = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
        ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
      };
    };
    environment.etc."netns/${cfg.namespace}/resolv.conf".text = "nameserver 9.9.9.9";

    systemd.services.${cfg.namespace} = {
      description = "${cfg.namespace} network interface";
      bindsTo = [ "netns@${cfg.namespace}.service" ];
      requires = [ "network-online.target" ];
      after = [ "netns@${cfg.namespace}.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart =
          with pkgs;
          writers.writeBash "wg-up" ''
            set -e
            # wg setconf (and bringing the link up) must happen *before* the
            # interface is moved into the isolated namespace: the kernel's
            # WireGuard transport socket binds to whatever namespace the
            # device is in at that moment, and stays there across a later
            # `ip link set netns` move. Doing it in this order means the
            # encrypted handshake/data packets are sent via this namespace's
            # real route to the internet, while only the *decrypted* tunneled
            # traffic (via the interface's own address/routes, set below) is
            # actually isolated inside the target namespace. Setting it up
            # the other way around (as this used to) leaves the transport
            # socket bound inside the target namespace too, whose only route
            # is the tunnel device itself - a routing loop that silently
            # drops every handshake packet (confirmed on odin: `wg show`
            # reported bytes "sent" but the peer never received anything).
            ${iproute2}/bin/ip link add wg0 type wireguard
            ${wireguard-tools}/bin/wg setconf wg0 ${cfg.configFile}
            ${iproute2}/bin/ip link set wg0 up
            ${iproute2}/bin/ip link set wg0 netns ${cfg.namespace}
            ${iproute2}/bin/ip -n ${cfg.namespace} address add ${cfg.privateIP} dev wg0
            ${iproute2}/bin/ip -n ${cfg.namespace} link set wg0 up
            ${iproute2}/bin/ip -n ${cfg.namespace} link set lo up
            ${iproute2}/bin/ip -n ${cfg.namespace} route add default dev wg0
          '';
        ExecStop =
          with pkgs;
          writers.writeBash "wg-down" ''
            set -e
            ${iproute2}/bin/ip -n ${cfg.namespace} route del default dev wg0
            ${iproute2}/bin/ip -n ${cfg.namespace} link del wg0
          '';
      };
    };

    systemd.services."${cfg.namespace}-healthcheck" = lib.mkIf cfg.healthcheck.enable {
      description = "Verify ${cfg.namespace} WireGuard tunnel has a live handshake, and recover it otherwise";
      after = [ "${cfg.namespace}.service" ];
      onFailure = lib.lists.optionals (config ? tg-notify && config.tg-notify.enable) [
        "tg-notify@${cfg.namespace}-healthcheck.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = "${cfg.namespace}-healthcheck";
        RuntimeDirectoryPreserve = "yes";
      };
      path = [
        pkgs.iproute2
        pkgs.wireguard-tools
        pkgs.systemd
        pkgs.coreutils
      ];
      script = ''
        set -uo pipefail
        ns="${cfg.namespace}"
        threshold=${toString cfg.healthcheck.staleAfterSec}
        marker="/run/${cfg.namespace}-healthcheck/unhealthy"

        healthy=0
        if ip netns exec "$ns" true 2>/dev/null; then
          handshakes=$(ip netns exec "$ns" wg show all latest-handshakes 2>/dev/null || true)
          now=$(date +%s)
          while read -r _iface _peer ts; do
            [ -z "''${ts:-}" ] && continue
            if [ "$ts" -gt 0 ] && [ $(( now - ts )) -lt "$threshold" ]; then
              healthy=1
            fi
          done <<< "$handshakes"
        fi

        if [ "$healthy" -eq 1 ]; then
          echo "$ns tunnel handshake is healthy"
          rm -f "$marker"
          exit 0
        fi

        echo "No live handshake on $ns tunnel within the last ''${threshold}s; recovering"
        systemctl restart "$ns.service"
        ${lib.concatMapStringsSep "\n        " (
          s: "systemctl restart ${lib.escapeShellArg s}.service || true"
        ) (lib.filter (s: s != cfg.namespace) cfg.monitoredServices)}

        if [ -e "$marker" ]; then
          echo "$ns tunnel was already known unhealthy; suppressing repeat alert"
          exit 0
        fi
        touch "$marker"
        exit 1
      '';
    };

    systemd.timers."${cfg.namespace}-healthcheck" = lib.mkIf cfg.healthcheck.enable {
      description = "Periodic health-check for the ${cfg.namespace} WireGuard tunnel";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "${toString cfg.healthcheck.intervalSec}s";
      };
    };
  };
}
