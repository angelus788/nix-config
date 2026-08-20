{ config, lib, pkgs, ... }:
let
  net = config.homelab.networks;
  mainNet = net.external.heimdall;
  wg0Net = net.local.wireguard-ext;

  # 1. Safely extract Heimdall IP (handles both string and set forms)
  heimdallRaw = if mainNet ? v4 then (if builtins.isAttrs mainNet.v4 then mainNet.v4.address else mainNet.v4) else "127.0.0.1";
  heimdallIp = lib.head (lib.splitString "/" (if heimdallRaw != null then heimdallRaw else "127.0.0.1"));

  # 2. Extract v4 network CIDR cleanly
  wg0V4Cidr = wg0Net.cidr.v4 or "10.5.0.0/24";
  wg0V4Prefix = lib.head (lib.splitString "/" wg0V4Cidr);
  wg0V4Subnet = "${lib.concatStringsSep "." (lib.take 3 (lib.splitString "." wg0V4Prefix))}.0/24";

  # 3. Extract v6 base safely
  wg0V6Raw = wg0Net.cidr.v6 or null;
  wg0V6Subnet = if wg0V6Raw != null then "${lib.head (lib.splitString "/" wg0V6Raw)}/64" else null;

  # NetNS parameters for external client tunnel
  netnsName = "wg_client";
  wgClientIf = "wg_client";
  secretPath = config.age.secrets.wireguardCredentials.path or "/run/agenix/wireguardCredentials";
in
{
  # ---------------------------------------------------------------------------
  # 1. Host Mesh Tunnel (odin <-> heimdall) via systemd-networkd
  # ---------------------------------------------------------------------------
  systemd.network = {
    enable = true;

    netdevs = {
      "50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig = {
          ListenPort = 51821;
          PrivateKeyFile = config.age.secrets.wireguardPrivateKeyOdin.path;
        };
        wireguardPeers = [
          {
            # heimdall (Hub)
            PublicKey = "3pFGJLF2uGPagy76AlqzDbS0kYyi/x8RikKEoy5XiB4=";
            Endpoint = "${heimdallIp}:51820";
            PersistentKeepalive = 25;
            AllowedIPs = [ wg0V4Subnet ] ++ lib.optional (wg0V6Subnet != null) wg0V6Subnet;
          }
        ];
      };
    };

    networks = {
      "60-wg0" = {
        matchConfig.Name = "wg0";

        # Don't block systemd-networkd-wait-online if wg0 takes time to handshake
        linkConfig.RequiredForOnline = "no";

        networkConfig = {
          Address = [
            "${wg0V4Prefix}/24"
          ] ++ lib.optional (wg0V6Subnet != null) "${lib.head (lib.splitString "/" wg0V6Raw)}/64";
        };
      };
    };
  };

  networking.firewall.allowedUDPPorts = [ 51821 ];

  # ---------------------------------------------------------------------------
  # 2. Isolated External Egress Tunnel (wg_client) in NetNS
  # ---------------------------------------------------------------------------
  systemd.services.wg_client = lib.mkForce {
    description = "WireGuard Network Namespace Service (${netnsName})";
    after = [ "network-online.target" "agenix.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [ pkgs.iproute2 pkgs.wireguard-tools pkgs.coreutils ];

    script = ''
      set -e

      # 1. Cleanup old instances and stale netns mounts
      ${pkgs.iproute2}/bin/ip netns del ${netnsName} 2>/dev/null || true
      ${pkgs.coreutils}/bin/rm -f /run/netns/${netnsName} /var/run/netns/${netnsName}
      ${pkgs.iproute2}/bin/ip link delete ${wgClientIf} 2>/dev/null || true

      # 2. Create target namespace
      ${pkgs.iproute2}/bin/ip netns add ${netnsName}

      # 3. Bring loopback interface UP inside netns
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link set lo up

      # 4. Create wireguard interface DIRECTLY inside target namespace
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link add ${wgClientIf} type wireguard

      # 5. Apply credentials INSIDE the network namespace
      ${pkgs.iproute2}/bin/ip netns exec ${netnsName} ${pkgs.wireguard-tools}/bin/wg setconf ${wgClientIf} ${secretPath}

      # 6. Assign IP, activate interface, and set default egress route
      ${pkgs.iproute2}/bin/ip -n ${netnsName} address add 10.5.0.2/32 dev ${wgClientIf}
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link set ${wgClientIf} up
      ${pkgs.iproute2}/bin/ip -n ${netnsName} route add default dev ${wgClientIf}
    '';

    postStop = ''
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link set ${wgClientIf} down 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link delete ${wgClientIf} 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip netns del ${netnsName} 2>/dev/null || true
      ${pkgs.coreutils}/bin/rm -f /run/netns/${netnsName} /var/run/netns/${netnsName}
    '';
  };
}
