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
      default = if cfg.role == "server" then [ "netbird-management" "netbird-signal" "coturn" ] else [ "netbird" ];
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

        # Route gRPC Signal traffic
        handle /signal.SignalExchange/* {
          reverse_proxy h2c://127.0.0.1:10000
        }

        # Serve the bundled dashboard files (now directly in the root of the derivation)
        handle {
        header /config.json Cache-Control "no-store"
          root * ${config.services.netbird.server.dashboard.finalDrv}
          try_files {path} {path}/ /index.html
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
  ]);
}

