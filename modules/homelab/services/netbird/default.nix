{ config, lib, pkgs, ... }:
let
  service = "netbird";
  cfg = config.homelab.services.${service};
  hasFail2ban = config.services ? fail2ban-cloudflare && config.services.fail2ban-cloudflare.enable;

  # Generate /env.config.js as a clean static Nix store file to prevent Caddy template injection bugs
  envConfigJs = pkgs.writeText "env.config.js" ''
    window.env = {
      "AUTH_AUTHORITY": "${cfg.oidc.issuer}",
      "AUTH_CLIENT_ID": "${cfg.oidc.clientId}",
      "AUTH_AUDIENCE": "${cfg.oidc.audience}",
      "AUTH_SUPPORTED_SCOPES": "openid profile email offline_access api",
      "NETBIRD_MGMT_API_ENDPOINT": "https://${cfg.url}",
      "NETBIRD_MGMT_GRPC_API_ENDPOINT": "https://${cfg.url}",
      "NETBIRD_AUTH_AUTHORITY": "${cfg.oidc.issuer}",
      "NETBIRD_AUTH_CLIENT_ID": "${cfg.oidc.clientId}",
      "NETBIRD_AUTH_AUDIENCE": "${cfg.oidc.audience}",
      "NETBIRD_AUTH_SUPPORTED_SCOPES": "openid profile email offline_access api",
      "USE_AUTH0": "false"
    };
    window._env_ = window.env;
  '';

  # Override the dashboard package build arguments so Vite/React compiles
  netbirdDashboardPatched = pkgs.netbird-dashboard.overrideAttrs (oldAttrs: {
    # If the package supports build-time environment injection (adjust variable names if needed by NetBird's build setup):
    preConfigure = (oldAttrs.preConfigure or "") + ''
      export VITE_AUTH_AUTHORITY="${cfg.oidc.issuer}"
      export VITE_AUTH_CLIENT_ID="${cfg.oidc.clientId}"
      export VITE_AUTH_AUDIENCE="${cfg.oidc.audience}"
      export AUTH_AUTHORITY="${cfg.oidc.issuer}"
      export AUTH_CLIENT_ID="${cfg.oidc.clientId}"
    '';
  });
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
      default = "Infrastructure";
    };
    role = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
      default = "client";
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Keycloak/OIDC integration";
      };
      issuer = lib.mkOption {
        type = lib.types.str;
        default = "https://login.internalnetwork.party/realms/netbird";
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
      services = {
        netbird.server = {
          enable = true;
          domain = cfg.url;

          dashboard = {
            enable = true;
            settings = lib.mkIf cfg.oidc.enable {
              AUTH_AUTHORITY = cfg.oidc.issuer;
              AUTH_CLIENT_ID = cfg.oidc.clientId;
              AUTH_AUDIENCE = cfg.oidc.audience;
              AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
              NETBIRD_MGMT_API_ENDPOINT = "https://${cfg.url}";
              NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://${cfg.url}";
              USE_AUTH0 = "false";
            };
          };

          management = {
            enable = true;
            turnDomain = cfg.url;
            oidcConfigEndpoint = lib.mkIf cfg.oidc.enable "${cfg.oidc.issuer}/.well-known/openid-configuration";
          };
          signal.enable = true;
        };

        caddy.virtualHosts."netbird.avgtechguy.com".extraConfig = ''
          route {
            # 1. Serve dynamic runtime environment file securely from the Nix store
            handle /env.config.js {
              header Content-Type "application/javascript"
              header Cache-Control "no-cache, no-store, must-revalidate"
              root * ${envConfigJs}
              file_server
            }

            # 2. Forward REST API calls to netbird-management backend
            handle /api/* {
              reverse_proxy http://127.0.0.1:8011
            }

            # 3. Serve static web dashboard frontend
            handle {
              root * ${netbirdDashboardPatched}
              try_files {path} {path}/ /index.html
              file_server
            }
          }
        '';
      };

      services.fail2ban-cloudflare.jails.netbird = lib.mkIf hasFail2ban {
        serviceName = "netbird-dashboard";
        failRegex = "^.*Failed login attempt for user.*IP: <HOST>.*$";
      };

      systemd.services.netbird-management = {
        serviceConfig.EnvironmentFile = [
          config.age.secrets.netbirdOidcSecret.path
        ];

        environment = {
          NETBIRD_MGMT_OIDC_ISSUER_ENDPOINT = cfg.oidc.issuer;
          NETBIRD_MGMT_OIDC_CLIENT_ID = cfg.oidc.clientId;
          NETBIRD_MGMT_OIDC_AUDIENCE = cfg.oidc.audience;
          NETBIRD_MGMT_AUTH_AUTHORITY = cfg.oidc.issuer;
        };

        preStart = lib.mkAfter ''
          if [ -f "$NETBIRD_STORE_ENGINE_DATA_STORE_ENCRYPTION_KEY" ] || [ -n "$NETBIRD_STORE_ENGINE_DATA_STORE_ENCRYPTION_KEY" ]; then ${pkgs.jq}/bin/jq --arg key "$NETBIRD_STORE_ENGINE_DATA_STORE_ENCRYPTION_KEY" '.DataStoreEncryptionKey = $key' /var/lib/netbird-mgmt/management.json > /var/lib/netbird-mgmt/management.json.tmp && mv /var/lib/netbird-mgmt/management.json.tmp /var/lib/netbird-mgmt/management.json; fi
        '';
      };
    })

    # Client Role (odin & other nodes)
    (lib.mkIf (cfg.role == "client") {
      services.netbird.enable = true;
    })
  ]);
}
