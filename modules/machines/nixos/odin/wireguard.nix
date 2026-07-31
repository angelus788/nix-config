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
            
            # Capital 'AllowedIPs' matching systemd option schema
            AllowedIPs = [ wg0V4Subnet ] ++ lib.optional (wg0V6Subnet != null) wg0V6Subnet;
          }
        ];
      };
    };

    networks = {
      "60-wg0" = {
        matchConfig.Name = "wg0";
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

    path = [ pkgs.iproute2 pkgs.wireguard-tools ];

    script = ''
      set -e

      # 1. Clean stale state
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link delete ${wgClientIf} 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip link delete ${wgClientIf} 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip netns del ${netnsName} 2>/dev/null || true

      # 2. Create namespace
      ${pkgs.iproute2}/bin/ip netns add ${netnsName}

      # 3. Create interface in root host namespace
      ${pkgs.iproute2}/bin/ip link add ${wgClientIf} type wireguard

      # 4. Configure credentials & FwMark in root namespace
      ${pkgs.wireguard-tools}/bin/wg setconf ${wgClientIf} /run/agenix/wireguardCredentials
      ${pkgs.wireguard-tools}/bin/wg set ${wgClientIf} fwmark 51820

      # 5. Move interface to namespace
      ${pkgs.iproute2}/bin/ip link set ${wgClientIf} netns ${netnsName}

      # 6. Bring up interfaces and add default route inside netns
      ${pkgs.iproute2}/bin/ip -n ${netnsName} address add 10.5.0.2/32 dev ${wgClientIf}
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link set ${wgClientIf} up
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link set lo up
      ${pkgs.iproute2}/bin/ip -n ${netnsName} route add default dev ${wgClientIf}
    '';

    postStop = ''
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link set ${wgClientIf} down 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip -n ${netnsName} link delete ${wgClientIf} 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip netns del ${netnsName} 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip link delete ${wgClientIf} 2>/dev/null || true
    '';
  };
}