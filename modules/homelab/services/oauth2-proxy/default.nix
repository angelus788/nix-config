{
  config,
  lib,
  ...
}:
let
  service = "oauth2-proxy";
  cfg = config.homelab.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "auth.internalnetwork.party";
      description = ''
        Dedicated hostname for this oauth2-proxy instance's own paths
        (/oauth2/auth, /oauth2/start, /oauth2/callback). Kept independent
        of any single protected app's domain or identity provider's domain
        - forward_auth-protected apps (currently just Microbin) point at
        this URL rather than hardcoding it, so this proxy (and whichever
        app it protects) doesn't silently break if an unrelated service
        sharing a domain with it is ever decommissioned. See git history
        for why this was split out of the keycloak module.
      '';
    };
    envFile = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression ''
        pkgs.writeText "oauth2proxy-envfile" '''
          OAUTH2_PROXY_CLIENT_SECRET=foobar
          OAUTH2_PROXY_COOKIE_SECRET=barfoo
        '''
      '';
    };
    oidc.pocketId = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "id.avgtechguy.com";
        description = ''
          Pocket ID's hostname. NOT `config.homelab.services.pocket-id.url`
          - same cross-host footgun documented in miniflux/default.nix and
          homepage/default.nix's `customUrls.pocket-id`: that option's
          value depends on which host reads it, and this oauth2-proxy
          instance runs on odin, where it was never overridden.
        '';
      };
      clientId = lib.mkOption {
        type = lib.types.str;
        default = "microbin";
        description = "Client ID of the OIDC client registered for this oauth2-proxy instance in Pocket ID.";
      };
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
    in
    mkIfElse (cfg.role == "client")
      # client
      (lib.mkIf cfg.enable {
        services.oauth2-proxy = {
          enable = true;
          keyFile = cfg.envFile;
          reverseProxy = true;
          trustedProxyIP = [
            "127.0.0.1/32"
            "::1/128"
          ];
          provider = "oidc";
          oidcIssuerUrl = "https://${cfg.oidc.pocketId.url}";

          cookie = {
            domain = ".internalnetwork.party";
            secure = true;
          };

          httpAddress = "127.0.0.1:4192";
          clientID = cfg.oidc.pocketId.clientId;
          upstream = [ "http://127.0.0.1:0/" ];

          scope = "openid profile email";
          email.domains = [ "*" ];

          # Pocket ID is on a different host with a single public hostname
          # (no loopback-vs-public split like Keycloak had), so real OIDC
          # discovery just works - no need for skip-oidc-discovery or
          # manually-mapped endpoints.
          extraConfig = {
            insecure-oidc-allow-unverified-email = "true";
            skip-provider-button = "true";
            code-challenge-method = "S256";
            whitelist-domain = ".internalnetwork.party";
          };
        };
        services.frp.instances.${config.networking.hostName}.settings.proxies = [
          {
            name = service;
            type = "tcp";
            localIP = "127.0.0.1";
            localPort = 4192;
            remotePort = 4192;
          }
        ];
      })
      # server
      {
        services.caddy.virtualHosts."${cfg.url}" = {
          useACMEHost = "internalnetwork.party";
          extraConfig = ''
            reverse_proxy http://127.0.0.1:4192
          '';
        };
      };
}
