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
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "news.internalnetwork.party";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Miniflux";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Minimalist and opinionated feed reader";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "miniflux-light.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };
    adminCredentialsFile = lib.mkOption {
      description = "File with admin credentials";
      type = lib.types.path;
    };
    role = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
      default = "client";
    };
  };
  config =
    let
      mkIfElse =
        p: yes: no:
        lib.mkMerge [
          (lib.mkIf p yes)
          (lib.mkIf (!p) no)
        ];
      addr = "127.0.0.1";
      port = 8067;
    in
    mkIfElse (cfg.role == "client")
      (lib.mkIf cfg.enable {
        services.${service} = {
          enable = true;
          adminCredentialsFile = cfg.adminCredentialsFile;
          config = {
            BASE_URL = "https://${cfg.url}";
            CREATE_ADMIN = true;
            LISTEN_ADDR = "${addr}:${toString port}";
            OAUTH2_PROVIDER = "oidc";
            OAUTH2_CLIENT_ID = "miniflux";

            OAUTH2_OIDC_AUTH_ENDPOINT = "https://login.internalnetwork.party/realms/master/protocol/openid-connect/auth";
            OAUTH2_OIDC_TOKEN_ENDPOINT = "https://login.internalnetwork.party/realms/master/protocol/openid-connect/token";
            OAUTH2_OIDC_USERINFO_ENDPOINT = "https://login.internalnetwork.party/realms/master/protocol/openid-connect/userinfo";
            OAUTH2_OIDC_JWKS_ENDPOINT = "https://login.internalnetwork.party/realms/master/protocol/openid-connect/certs";

            OAUTH2_REDIRECT_URL = "https://${cfg.url}/oauth2/oidc/callback";
            OAUTH2_OIDC_DISCOVERY_ENDPOINT = "http://login.internalnetwork.party:8821/realms/master";
            #OAUTH2_OIDC_DISCOVERY_ENDPOINT = "http://127.0.0.1:8821/realms/master";
            #OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://login.internalnetwork.party/realms/master";
            #OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${hl.services.keycloak.url}/realms/master";
            OAUTH2_USER_CREATION = "1";
            DISABLE_LOCAL_AUTH = "true";
          };
        };
        services.frp.settings.proxies = [
          {
            name = service;
            type = "tcp";
            localIP = addr;
            localPort = port;
            remotePort = port;
          }
        ];
      })
      {
        services.caddy.virtualHosts."${cfg.url}" = {
          useACMEHost = "internalnetwork.party";
          extraConfig = ''
            reverse_proxy 127.0.0.1:8821 {
                  header_up X-Forwarded-Proto https
                  header_up Host {host}
                  header_up X-Real-IP {remote_host}
                  header_up X-Forwarded-For {remote_host}
                }
          '';
        };
      };
}# reverse_proxy http://${addr}:${toString port}
