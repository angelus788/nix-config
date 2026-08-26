{ config, lib, pkgs, ... }:
let
  service = "netbird";
  cfg = config.homelab.services.${service};
  hasFail2ban = config.services ? fail2ban-cloudflare && config.services.fail2ban-cloudflare.enable;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/netbird";
    };

    netbirdUrl = lib.mkOption {
      type = lib.types.str;
      default = "netbird.avgtechguy.com";
      example = "netbird.avgtechguy.com";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "netbird.avgtechguy.com";
    };

    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "NetBird";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "WireGuard overlay network manager";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "netbird.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };
    role = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
      default = "client";
    };
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default =
        (if cfg.role == "server" then [ "netbird-management" "netbird-signal" "coturn" ] else [ "netbird" ])
        ++ lib.optional cfg.proxy.enable "podman-netbird-proxy";
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Keycloak/OIDC integration";
      };
      issuer = lib.mkOption {
        type = lib.types.str;
        default = "https://login.internalnetwork.party/realms/master";
        description = "OIDC Issuer / Realm URL";
      };
      clientId = lib.mkOption {
        type = lib.types.str;
        default = "netbird-dashboard";
        description = "Client ID configured in Keycloak";
      };
      audience = lib.mkOption {
        type = lib.types.str;
        default = "netbird-dashboard";
        description = "OIDC Audience value";
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to file containing OIDC client secret environment variables";
      };
    };

    dns = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "netbird.selfhosted";
        example = "nb.avgtechguy.com";
        description = "Domain suffix for peer DNS resolution (NetBird's MagicDNS equivalent, e.g. <peer-hostname>.<domain>). Resolved entirely client-side by each peer's local NetBird daemon - never queried against public DNS, so it doesn't need to be a domain you own, though using one avoids any chance of shadowing a real site while connected.";
      };
    };

    proxy = {
      enable = lib.mkEnableOption {
        description = "Bring-your-own-proxy (BYOP) account cluster, exposing NetBird-only services over an internet-facing reverse proxy";
      };
      domain = lib.mkOption {
        type = lib.types.str;
        example = "proxy.avgtechguy.com";
        description = "Apex domain of the account proxy-cluster. An A record for this domain and a wildcard CNAME (*.<domain>) must point at `address`.";
      };
      address = lib.mkOption {
        type = lib.types.str;
        example = "152.42.152.248";
        description = "Public IPv4 the proxy container binds ports 80/443 to. Kept distinct from the host's primary IP so it doesn't collide with an existing reverse proxy (e.g. Caddy) bound there.";
      };
      interface = lib.mkOption {
        type = lib.types.str;
        example = "ens3";
        description = "Interface `address` is added to. Applied imperatively (ip addr replace) rather than declaratively, since the interface may already be owned by another .network file (e.g. cloud-init's generated config) that takes precedence over any Nix-managed one.";
      };
      caddyBindAddresses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "159.65.167.45" ];
        description = ''
          A specific-address bind can only coexist with an already-active wildcard
          (0.0.0.0) bind on the same port if the wildcard one is narrowed away —
          Linux gives the wildcard listener the whole port otherwise, regardless of
          bind order. If Caddy already wildcard-binds 80/443 on this host, list its
          own address(es) here so Caddy's global `default_bind` is narrowed to just
          those, freeing `address` for the proxy container. Leave empty if nothing
          else on this host binds 80/443.
        '';
      };
      tokenFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to an env file containing NB_PROXY_TOKEN=<account-scoped proxy token>";
      };
      certDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/netbird-proxy/certs";
      };
      private = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Restrict proxied services to NetBird peers only (NB_PROXY_PRIVATE)";
      };
      image = lib.mkOption {
        type = lib.types.str;
        default = "netbirdio/reverse-proxy:latest";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Server Role (heimdall)
    (lib.mkIf (cfg.role == "server") {
      services.netbird.server = {
        enable = true;
        domain = cfg.url;

        dashboard = {
          enable = true;
          settings = {
            AUTH_AUTHORITY = cfg.oidc.issuer;
            AUTH_CLIENT_ID = cfg.oidc.clientId;
            AUTH_AUDIENCE = cfg.oidc.audience;
            AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
            NETBIRD_MGMT_API_ENDPOINT = "https://${cfg.url}";
            NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://${cfg.url}";
            USE_AUTH0 = false;
          };
        };

        management = {
          enable = true;
          turnDomain = cfg.url;
          dnsDomain = cfg.dns.domain;
          oidcConfigEndpoint = "${cfg.oidc.issuer}/.well-known/openid-configuration";
          settings = {
            DataStoreEncryptionKey = {
              _secret = config.age.secrets.netbirdDataStoreEncryptionKey.path;
            };
            TURNConfig.Secret = {
              _secret = config.age.secrets.netbirdTurnSecret.path;
            };
            PKCEAuthorizationFlow.ProviderConfig = {
              Audience = cfg.oidc.audience;
              ClientID = cfg.oidc.clientId;
              Scope = "openid profile email offline_access api";
              UseIDToken = true;
            };
            DeviceAuthorizationFlow.ProviderConfig = {
              Audience = cfg.oidc.audience;
              ClientID = cfg.oidc.clientId;
              Scope = "openid profile email offline_access api";
            };
          };
        };
        signal.enable = true;

        coturn = {
          enable = true;
          domain = cfg.url;
          passwordFile = config.age.secrets.netbirdTurnPassword.path;
        };
      };

      services.caddy.virtualHosts."netbird.avgtechguy.com".extraConfig = ''
        # Route standard REST API traffic to management
        handle /api/* {
          reverse_proxy http://127.0.0.1:8011
        }

        # Route gRPC Management traffic (requires h2c for unencrypted local proxying)
        handle /management.ManagementService/* {
          reverse_proxy h2c://127.0.0.1:8011
        }

        # Route gRPC ProxyService traffic (used by BYOP reverse-proxy clusters)
        handle /management.ProxyService/* {
          reverse_proxy h2c://127.0.0.1:8011
        }

        # Route gRPC Signal traffic
        handle /signal.SignalExchange/* {
          reverse_proxy h2c://127.0.0.1:10000
        }

        # Serve the bundled dashboard files (now directly in the root of the derivation)
        handle {
        header /config.json Cache-Control "no-store"
          root * ${config.services.netbird.server.dashboard.finalDrv}
          try_files {path} {path}.html {path}/index.html /index.html
          file_server
        }
      '';

      services.fail2ban-cloudflare.jails.netbird = lib.mkIf hasFail2ban {
        serviceName = "netbird-dashboard";
        failRegex = "^.*Failed login attempt for user.*IP: <HOST>.*$";
      };

      systemd.services.netbird-management = {
        # netbird-management does a hard OIDC-discovery check against Keycloak
        # (on a different host) at every startup and refuses to boot if it
        # fails. If both restart around the same time (e.g. nightly auto-
        # upgrade on both hosts), the default 5-tries-in-10s limit gives up
        # long before Keycloak finishes booting. Retry patiently instead.
        startLimitIntervalSec = 900;
        startLimitBurst = 50;
        serviceConfig = {
          EnvironmentFile = [
            config.age.secrets.netbirdOidcSecret.path
          ];
          RestartSec = 15;
        };

        environment = {
          NETBIRD_MGMT_OIDC_ISSUER_ENDPOINT = cfg.oidc.issuer;
          NETBIRD_MGMT_OIDC_CLIENT_ID = cfg.oidc.clientId;
          NETBIRD_MGMT_OIDC_AUDIENCE = cfg.oidc.audience;
          NETBIRD_MGMT_AUTH_AUTHORITY = cfg.oidc.issuer;
          # Force the OIDC config endpoint explicitly to the Keycloak domain
          NETBIRD_MGMT_OIDC_CONFIGURATION_ENDPOINT = "${cfg.oidc.issuer}/.well-known/openid-configuration";
        };
      };
    })

    # Client Role (odin & other nodes)
    (lib.mkIf (cfg.role == "client") {
      services.netbird.enable = true;
    })

    # BYOP account proxy-cluster (heimdall)
    (lib.mkIf cfg.proxy.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.proxy.certDir} 0750 root root - -"
      ];

      services.caddy.globalConfig = lib.optionalString (cfg.proxy.caddyBindAddresses != [ ]) ''
        default_bind ${lib.concatStringsSep " " cfg.proxy.caddyBindAddresses}
      '';

      # Applied imperatively: `interface` is typically already owned by another
      # .network file (e.g. cloud-init's generated config), which wins over any
      # Nix-managed .network file matching the same link, so declaring this
      # address via systemd.network.networks would silently have no effect.
      systemd.services.netbird-proxy-address = {
        description = "Assign reserved IP for the NetBird BYOP proxy to ${cfg.proxy.interface}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.iproute2}/bin/ip -4 addr replace ${cfg.proxy.address}/32 dev ${cfg.proxy.interface}";
        };
      };

      systemd.services.podman-netbird-proxy = {
        after = [ "netbird-proxy-address.service" ];
        requires = [ "netbird-proxy-address.service" ];
      };

      virtualisation.oci-containers.containers.netbird-proxy = {
        image = cfg.proxy.image;
        autoStart = true;
        ports = [
          "${cfg.proxy.address}:80:80"
          "${cfg.proxy.address}:443:443"
        ];
        volumes = [
          "${cfg.proxy.certDir}:/certs"
        ];
        environment = {
          NB_PROXY_DOMAIN = cfg.proxy.domain;
          NB_PROXY_MANAGEMENT_ADDRESS = "https://${cfg.url}";
          NB_PROXY_CERTIFICATE_DIRECTORY = "/certs";
          NB_PROXY_ACME_CERTIFICATES = "true";
          NB_PROXY_PRIVATE = if cfg.proxy.private then "true" else "false";
        };
        extraOptions = [
          "--pull=newer"
          "--env-file=${cfg.proxy.tokenFile}"
          # The container runs as an unprivileged uid and can't bind 80/443 in its
          # own netns without this — without it, podman falls back to a host-side
          # privileged pre-bind that conflicts with netavark's DNAT rule for the
          # same published address, and every connection gets refused.
          "--cap-add=NET_BIND_SERVICE"
        ];
      };
    })
  ]);
}

