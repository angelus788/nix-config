{ config
, lib
, ...
}:
let
  service = "miniflux";
  hl = config.homelab;
  cfg = hl.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Enable ${service}";
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "news.internalnetwork.party";
    };
    homepage = {
      name = lib.mkOption { type = lib.types.str; default = "Miniflux"; };
      description = lib.mkOption { type = lib.types.str; default = "Minimalist feed reader"; };
      icon = lib.mkOption { type = lib.types.str; default = "miniflux-light.svg"; };
      category = lib.mkOption { type = lib.types.str; default = "Services"; };
    };
    adminCredentialsFile = lib.mkOption {
      description = "File with admin credentials";
      type = lib.types.path;
    };
    role = lib.mkOption {
      type = lib.types.enum [ "client" "server" ];
      default = "client";
    };
  };

  config = lib.mkMerge [
    # --- CLIENT ROLE: The Miniflux Service ---
    (lib.mkIf (cfg.enable && cfg.role == "client") {
      services.${service} = {
        enable = true;
        adminCredentialsFile = cfg.adminCredentialsFile;
        config = {
          # Boolean type (no quotes)
          CREATE_ADMIN = true;

          LISTEN_ADDR = "127.0.0.1:8067";
          OAUTH2_PROVIDER = "oidc";
          OAUTH2_CLIENT_ID = "miniflux";

          OAUTH2_OIDC_AUTH_ENDPOINT = "https://login.internalnetwork.party/realms/master/protocol/openid-connect/auth";

          # Server-to-server uses internal path (Keep this as is)
          OAUTH2_OIDC_DISCOVERY_ENDPOINT = "http://login.internalnetwork.party:8821/realms/master";
          OAUTH2_OIDC_TOKEN_ENDPOINT = "http://login.internalnetwork.party:8821/realms/master/protocol/openid-connect/token";
          # String types (with quotes)
          OAUTH2_USER_CREATION = "1";
          DISABLE_LOCAL_AUTH = "1";
          BASE_URL = "https://${cfg.url}";
        };
      };

      services.frp.settings.proxies = [{
        name = service;
        type = "tcp";
        localIP = "127.0.0.1";
        localPort = 8067;
        remotePort = 8067;
      }];
    })

    # --- SERVER ROLE: Caddy Reverse Proxy ---
    (lib.mkIf (cfg.enable && cfg.role == "server") {
      services.caddy.virtualHosts = {
        # Redirect for the Miniflux Web UI
        "${cfg.url}" = {
          useACMEHost = "internalnetwork.party";
          extraConfig = ''
            reverse_proxy http://127.0.0.1:8067
          '';
        };

        # Redirect for Keycloak (The login subdomain)
        "login.internalnetwork.party" = {
          useACMEHost = "internalnetwork.party";
          extraConfig = ''
            reverse_proxy http://127.0.0.1:8821 {
              header_up Host {host}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-Proto https
              header_up X-Forwarded-Host {host}
            }
          '';
        };
      };
    })
  ];
}
