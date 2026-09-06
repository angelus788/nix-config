{
  config,
  lib,
  ...
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
      name = lib.mkOption {
        type = lib.types.str;
        default = "Miniflux";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Minimalist feed reader";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "miniflux-light.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
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

    oidc.pocketId = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "id.avgtechguy.com";
        description = ''
          Pocket ID's hostname. NOT `config.homelab.services.pocket-id.url`
          - that option's actual value depends on which host it's read
          from: Pocket ID only runs on heimdall, which overrides it to
          this same "id.avgtechguy.com" for its own NetBird OIDC-failover
          rehearsal, but Miniflux's client runs on odin, where that option
          was never overridden and just returns the unrelated module
          default ("id.internalnetwork.party", a hostname with no DNS
          record) - same cross-host footgun already documented in
          homepage/default.nix's `customUrls.pocket-id` override.
        '';
      };
      clientId = lib.mkOption {
        type = lib.types.str;
        default = "miniflux";
        description = "Client ID of the OIDC client registered for Miniflux in Pocket ID.";
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to an agenix-decrypted EnvironmentFile (systemd.exec(5)
          format, i.e. `OAUTH2_CLIENT_SECRET=...`, not a raw value like
          Forgejo's clientSecretFile) containing Miniflux's OAuth2 client
          secret from Pocket ID. Miniflux's own `config` submodule renders
          directly to plaintext systemd unit environment= lines in the
          (world-readable) nix store, so the secret can't go through
          `services.miniflux.config` like the rest of the OAuth2 settings -
          it's injected as an extra EnvironmentFile instead, alongside the
          module's own adminCredentialsFile (systemd merges multiple
          EnvironmentFile= entries).
        '';
      };
      clientSecretSourceFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          The encrypted .age file clientSecretFile is decrypted from (i.e.
          age.secrets.<name>.file, not .path). Used only as a restart
          trigger: agenix decrypts to the same runtime path on every
          activation regardless of whether the secret actually changed, so
          miniflux.service would never notice a rotated secret and keep
          running with the stale one in memory until manually restarted -
          hit this exact issue after recreating the Pocket ID client. Same
          pattern as forgejo's clientSecretSourceFile/netbird's
          proxy.tokenSourceFile.
        '';
      };
    };
  };

  config = lib.mkMerge [
    # --- CLIENT ROLE: The Miniflux Service ---
    (lib.mkIf (cfg.enable && cfg.role == "client") {
      services.${service} = {
        enable = true;
        adminCredentialsFile = cfg.adminCredentialsFile;
        config = {
          CREATE_ADMIN = true;
          LISTEN_ADDR = "0.0.0.0:8067";
          OAUTH2_PROVIDER = "oidc";
          # Without this, Miniflux rejects any OIDC login with a bare
          # "Forbidden" unless that identity is already linked to an
          # existing Miniflux account - there's no such link for a new
          # Pocket ID identity, only the local CREATE_ADMIN account exists.
          OAUTH2_USER_CREATION = "1";
          OAUTH2_CLIENT_ID = cfg.oidc.pocketId.clientId;
          # Pocket ID (unlike the Keycloak setup this replaced) runs on a
          # different host than Miniflux's client, so there's no local
          # loopback shortcut available for the backend-to-backend calls -
          # every endpoint, browser-facing or not, is the same public
          # hostname. That also means no issuer mismatch, so (unlike the
          # old Keycloak config) OAUTH2_OIDC_SKIP_ISSUER_VERIFICATION isn't
          # needed here.
          OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${cfg.oidc.pocketId.url}";
          OAUTH2_OIDC_AUTH_ENDPOINT = "https://${cfg.oidc.pocketId.url}/authorize";
          OAUTH2_OIDC_TOKEN_ENDPOINT = "https://${cfg.oidc.pocketId.url}/api/oidc/token";
          OAUTH2_OIDC_USERINFO_ENDPOINT = "https://${cfg.oidc.pocketId.url}/api/oidc/userinfo";
          OAUTH2_OIDC_JWKS_ENDPOINT = "https://${cfg.oidc.pocketId.url}/.well-known/jwks.json";
          OAUTH2_REDIRECT_URL = "https://news.internalnetwork.party/oauth2/oidc/callback";
          BASE_URL = "https://news.internalnetwork.party";
        };
      };

      systemd.services.miniflux.serviceConfig.EnvironmentFile = [
        cfg.oidc.pocketId.clientSecretFile
      ];
      systemd.services.miniflux.restartTriggers = lib.optional (
        cfg.oidc.pocketId.clientSecretSourceFile != null
      ) cfg.oidc.pocketId.clientSecretSourceFile;

      services.frp.instances.${config.networking.hostName}.settings.proxies = [
        {
          name = service;
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 8067;
          remotePort = 8067;
        }
      ];
    })

    # --- SERVER ROLE: Caddy Reverse Proxy ---
    # Not gated by cfg.enable, unlike the client role above - matches every
    # other service's role split in this repo (nextcloud, navidrome,
    # microbin, vaultwarden, keycloak), where the server-role Caddy vhost
    # depends only on role. This module used to require both, which meant
    # heimdall's `miniflux.role = "server";` (following the same convention
    # as every other service there, none of which also set `.enable`) never
    # actually produced a Caddy vhost - the site was unreachable through
    # heimdall's Caddy from the day this was first set up.
    (lib.mkIf (cfg.role == "server") {
      services.caddy.virtualHosts."${cfg.url}" = {
        useACMEHost = "internalnetwork.party";
        extraConfig = ''
          reverse_proxy http://127.0.0.1:8067
        '';
      };
    })
  ];
}
