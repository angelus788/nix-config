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
        (
          if cfg.role == "server" then
            [
              "netbird-management"
              "netbird-signal"
              "coturn"
              "netbird-relay"
            ]
          else
            [ "netbird" ]
        )
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
      scope = lib.mkOption {
        type = lib.types.str;
        default = "openid profile email offline_access api";
        description = ''
          Scopes requested from the OIDC provider. Defaults match Keycloak,
          where `api` is a custom client scope mapper this repo's Keycloak
          setup provides. Other providers (e.g. pocket-id, used as an
          emergency failover issuer) won't recognize `api` - override to
          "openid profile email offline_access" for those.
        '';
      };
      idpSyncEnabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to configure IdpManagerConfig (Keycloak admin-API user
          sync). ClientConfig.TokenEndpoint/ExtraConfig.AdminEndpoint below
          are Keycloak-specific URL shapes - management polls
          TokenEndpoint on essentially every dashboard API request to fetch
          a service-account token. Against a non-Keycloak issuer with no
          such route (e.g. pocket-id, used as an emergency failover issuer),
          that request 200s into the provider's SPA fallback HTML instead
          of 404ing, and management's JSON decode of it fails with
          "invalid character '<' looking for beginning of value" - which
          surfaces as every JWT on /api/* being rejected as invalid, not as
          a sync-specific error. Set to false for providers without a
          Keycloak-compatible admin API.
        '';
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
        description = "Public-facing IPv4 for the proxy-cluster's DNS records and TLS certs. Kept distinct from the host's primary IP so it doesn't collide with an existing reverse proxy (e.g. Caddy) bound there.";
      };
      bindAddress = lib.mkOption {
        type = lib.types.str;
        default = cfg.proxy.address;
        example = "10.17.0.5";
        description = ''
          Local address the proxy container's published ports (80/443) actually
          bind to. Usually the same as `address`, but on providers where `address`
          is a reserved/floating IP that gets NAT'd onto a different local address
          before delivery (e.g. DigitalOcean's "anchor IP" - see
          `curl 169.254.169.254/metadata/v1/interfaces/public/0/anchor_ipv4/address`
          from the droplet), this must be set to that local address instead, or
          inbound traffic will never match the bind and connections will be
          refused despite `address` looking correctly configured.
        '';
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
      tokenSourceFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "config.age.secrets.netbirdProxyToken.file";
        description = ''
          The encrypted .age file `tokenFile` is decrypted from (i.e.
          `age.secrets.<name>.file`, not `.path`). Used only as a
          restart trigger: agenix decrypts to the same runtime path on every
          activation regardless of whether the token actually changed, so
          the container never noticed a rotated token and kept retrying
          with the stale one until NetBird's management server rate-limited
          it. This store path's hash changes whenever the encrypted source
          changes, which content-addresses a real rotation and forces a
          restart without over-triggering on unrelated deploys.
        '';
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
            AUTH_SUPPORTED_SCOPES = cfg.oidc.scope;
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
            # NetBird's own dedicated relay protocol (distinct from the TURN/coturn
            # config above) - required for "Lazy Connections" and "Force Relay" to
            # work at all. Without this, clients requesting a relayed connection
            # have no relay server to fall back to and just hang in "Connecting".
            Relay = {
              Addresses = [ "rels://${cfg.url}:443" ];
              CredentialsTTL = "12h";
              Secret = {
                _secret = config.age.secrets.netbirdRelaySecret.path;
              };
            };
            PKCEAuthorizationFlow.ProviderConfig = {
              Audience = cfg.oidc.audience;
              ClientID = cfg.oidc.clientId;
              Scope = cfg.oidc.scope;
              UseIDToken = true;
            };
            DeviceAuthorizationFlow.ProviderConfig = {
              Audience = cfg.oidc.audience;
              ClientID = cfg.oidc.clientId;
              Scope = cfg.oidc.scope;
            };
            # Without this, HttpConfig.AuthAudience stays empty (the module's
            # own default HttpConfig only sets Address/OIDCConfigEndpoint/
            # IdpSignKeyRefreshEnabled) and management's buildJWTConfig always
            # returns nil - which makes NetBird's embedded SSH server
            # permanently fail with "SSH server requires valid JWT
            # configuration" for any peer whose SSH server hasn't already
            # been running since before this was noticed.
            HttpConfig = {
              AuthAudience = cfg.oidc.audience;
              AuthClientID = cfg.oidc.clientId;
            };
          } // lib.optionalAttrs cfg.oidc.idpSyncEnabled {
            # Keycloak service-account client (see modules/homelab/services/keycloak) that lets
            # netbird-management sync/invite users. Read-only "view-users" role only - it cannot
            # write or delete anything in Keycloak.
            IdpManagerConfig = {
              ManagerType = "keycloak";
              ClientConfig = {
                ClientID = "netbird-backend";
                ClientSecret = {
                  _secret = config.age.secrets.netbirdIdpClientSecret.path;
                };
                GrantType = "client_credentials";
                Issuer = cfg.oidc.issuer;
                TokenEndpoint = "${cfg.oidc.issuer}/protocol/openid-connect/token";
              };
              ExtraConfig = {
                AdminEndpoint = lib.replaceStrings [ "/realms/" ] [ "/admin/realms/" ] cfg.oidc.issuer;
              };
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

        # Route gRPC Signal traffic (protobuf package is "signalexchange", not "signal")
        handle /signalexchange.SignalExchange/* {
          reverse_proxy h2c://127.0.0.1:10000
        }

        # Route NetBird's dedicated relay protocol (websocket, not gRPC) - required
        # for "Lazy Connections" and "Force Relay" to work.
        handle /relay* {
          reverse_proxy 127.0.0.1:33080
        }

        # Route the WebSocket-wrapped gRPC transport the browser/WASM client
        # uses (real gRPC over HTTP/2 isn't available in a browser) - this is
        # what backs the dashboard's "SSH"/"RDP" buttons, which spin up a
        # NetBird client compiled to WASM directly in the tab. Without these,
        # that traffic falls through to the default handle block (dashboard
        # static files) instead of reaching management/signal, and the WASM
        # client's gRPC dial fails with "WebSocket connection failed" no
        # matter which peer it's targeting. Paths from
        # util/wsproxy/constants.go; management multiplexes its own
        # /ws-proxy/management internally (same port as /api/*), while
        # /ws-proxy/signal needs the signal server's own port.
        handle /ws-proxy/management* {
          reverse_proxy 127.0.0.1:8011
        }
        handle /ws-proxy/signal* {
          reverse_proxy 127.0.0.1:10000
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

      # NetBird's dedicated relay server. Distinct from coturn (classic TURN/STUN,
      # used for ICE candidate gathering) - this is required for the client-side
      # "Lazy Connections" and "Force Relay" features, which specifically target
      # this protocol rather than falling back to TURN. Bound to loopback only;
      # exposed publicly via the /relay* Caddy route above rather than opening a
      # second port, since the relay protocol is plain websocket over TLS and
      # Caddy already terminates TLS for this domain.
      systemd.services.netbird-relay = {
        description = "NetBird dedicated relay server";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ config.age.secrets.netbirdRelaySecret.file ];
        serviceConfig = {
          # DynamicUser means this service can't read the agenix-decrypted
          # secret directly (root-owned, restrictive perms) - LoadCredential
          # has systemd itself (running as root) read it and hand it over via
          # a service-private credentials directory instead.
          LoadCredential = "relay-secret:${config.age.secrets.netbirdRelaySecret.path}";
          ExecStart = "${pkgs.writeShellScript "netbird-relay-start" ''
            exec ${pkgs.netbird-relay}/bin/netbird-relay \
              --listen-address 127.0.0.1:33080 \
              --exposed-address rels://${cfg.url}:443 \
              --health-listen-address 127.0.0.1:9093 \
              --metrics-port 9092 \
              --auth-secret "$(${pkgs.systemd}/bin/systemd-creds cat relay-secret)"
          ''}";
          DynamicUser = true;
          Restart = "always";
          RestartSec = 15;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };
    })

    # Client Role (odin & other nodes)
    (lib.mkIf (cfg.role == "client") {
      services.netbird.enable = true;
    })

    # BYOP account proxy-cluster (heimdall)
    (lib.mkIf cfg.proxy.enable {
      # The container has no userns remapping, so its internal uid/gid 1000
      # (the "netbird" user baked into the image) is literally host uid/gid
      # 1000 for volume permission purposes - owning this root:root broke
      # ACME cert issuance entirely (permission denied writing lock/key files).
      systemd.tmpfiles.rules = [
        "d ${cfg.proxy.certDir} 0750 1000 1000 - -"
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
        restartTriggers = lib.optional (cfg.proxy.tokenSourceFile != null) cfg.proxy.tokenSourceFile;
      };

      virtualisation.oci-containers.containers.netbird-proxy = {
        image = cfg.proxy.image;
        autoStart = true;
        # The container's single "main listener" binds internally on :8443
        # (it multiplexes plain HTTP and TLS/ALPN on one socket) - nothing
        # ever listens on 80/443 inside the container, so both host ports
        # must forward there instead of 1:1.
        ports = [
          "${cfg.proxy.bindAddress}:80:8443"
          "${cfg.proxy.bindAddress}:443:8443"
        ];
        volumes = [
          "${cfg.proxy.certDir}:/certs"
        ];
        environment = {
          NB_PROXY_DOMAIN = cfg.proxy.domain;
          NB_PROXY_MANAGEMENT_ADDRESS = "https://${cfg.url}";
          NB_PROXY_CERTIFICATE_DIRECTORY = "/certs";
          NB_PROXY_ACME_CERTIFICATES = "true";
          # Defaults to tls-alpn-01, but Let's Encrypt has been declining to
          # offer that challenge type for this account/authz ("no viable
          # challenge type found" during cert prefetch). http-01 only needs
          # port 80, which is already forwarded to the container below.
          NB_PROXY_ACME_CHALLENGE_TYPE = "http-01";
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

