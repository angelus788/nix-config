{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  service = "forgejo";
  cfg = config.homelab.services.${service};
  hl = config.homelab;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "git.${hl.baseDomain}";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Forgejo";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "A painless, self-hosted Git service";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "forgejo.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };

    oidc.pocketId = {
      enable = lib.mkEnableOption {
        description = "Register Pocket ID as an additional OAuth2/OIDC login source in Forgejo, alongside any existing sources (e.g. Keycloak)";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "pocket-id";
        description = ''
          Forgejo's internal name for this auth source. Also fixes the OAuth
          callback URL Forgejo expects (`/user/oauth2/<name>/callback`) - the
          OIDC client registered in Pocket ID must use that exact callback
          URL, so don't change this without updating the client there too.
        '';
      };
      clientId = lib.mkOption {
        type = lib.types.str;
        description = "Client ID of the OIDC client registered for Forgejo in Pocket ID. Not secret, but has no sane default - must be filled in per-deployment after registering the client.";
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to an agenix-decrypted file containing just the raw client secret from Pocket ID (age.secrets.<name>.path, not .file).";
      };
      clientSecretSourceFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          The encrypted .age file clientSecretFile is decrypted from (i.e.
          age.secrets.<name>.file, not .path). Used only as a restart
          trigger: agenix decrypts to the same runtime path on every
          activation regardless of whether the secret actually changed, so
          the oauth-registration service would never notice a rotated
          secret and keep re-applying the stale one. This store path's hash
          changes whenever the encrypted source changes, which
          content-addresses a real rotation without over-triggering on
          unrelated deploys (see netbird's proxy.tokenSourceFile for the
          same pattern).
        '';
      };
      discoveryUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://${config.homelab.services.pocket-id.url}/.well-known/openid-configuration";
        description = "Pocket ID's OpenID Connect discovery endpoint.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    services.openssh.settings.AcceptEnv = [ "GIT_PROTOCOL" ];

    services.openssh.extraConfig = ''
      Match User forgejo
        AuthorizedKeysCommand ${config.services.forgejo.package}/bin/forgejo keys -c /var/lib/forgejo/custom/conf/app.ini -e forgejo -u %u -t %t -k %k
        AuthorizedKeysCommandUser forgejo
    '';

    services.forgejo = {
      package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.forgejo;
      enable = true;
      database.type = "postgres";
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = cfg.url;
          ROOT_URL = "https://${cfg.url}/";
          HTTP_PORT = 3000;
          LANDING_PAGE = "/avgtechguy";
          SSH_PORT = lib.head config.services.openssh.ports;
          START_SSH_SERVER = false;
        };
        
        ssh = {
          # Ensures Forgejo maintains /var/lib/forgejo/.ssh/authorized_keys
          CREATE_AUTHORIZED_KEYS_FILE = true;
          # Disables token verification modal so keys/deploy keys add seamlessly in UI
          ENABLE_SSH_KEY_VERIFICATION = false;
        };

        log = {
          LEVEL = "Trace";
        };
        service = {
          DISABLE_REGISTRATION = true;
          ENABLE_NOTIFY_MAIL = true;
          REGISTER_EMAIL_CONFIRM = true;
        };
        mailer = {
          ENABLED = true;
          FROM = config.email.fromAddress;
          PROTOCOL = "sendmail";
          SENDMAIL_PATH = "/run/wrappers/bin/sendmail";
        };
      };
    };
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}
        request_body {
          max_size 10GB
        }
      '';
    };

    # Forgejo has no declarative option for OAuth2/OIDC *login* sources (its
    # own `oauth2` settings block is only for Forgejo acting as a provider
    # to other apps) - registering one is only possible via the admin CLI
    # or web UI. Runs idempotently on every activation: looks up an existing
    # source by name and updates it if found, otherwise creates it, so
    # re-running (e.g. after a client-secret rotation) converges instead of
    # erroring on "already exists" or drifting.
    systemd.services.forgejo-oauth-pocket-id = lib.mkIf cfg.oidc.pocketId.enable {
      description = "Register Pocket ID as a Forgejo OAuth2 login source";
      after = [ "forgejo.service" ];
      requires = [ "forgejo.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = lib.optional (
        cfg.oidc.pocketId.clientSecretSourceFile != null
      ) cfg.oidc.pocketId.clientSecretSourceFile;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "forgejo";
        WorkingDirectory = config.services.forgejo.stateDir;
      };
      environment = {
        FORGEJO_WORK_DIR = config.services.forgejo.stateDir;
        FORGEJO_CUSTOM = "${config.services.forgejo.stateDir}/custom";
      };
      path = [ config.services.forgejo.package ];
      script = ''
        set -euo pipefail

        name=${lib.escapeShellArg cfg.oidc.pocketId.name}
        secret=$(cat ${lib.escapeShellArg cfg.oidc.pocketId.clientSecretFile})

        existingId=$(forgejo admin auth list | awk -v name="$name" '$2 == name { print $1 }')

        if [ -n "$existingId" ]; then
          forgejo admin auth update-oauth \
            --id "$existingId" \
            --name "$name" \
            --provider openidConnect \
            --key ${lib.escapeShellArg cfg.oidc.pocketId.clientId} \
            --secret "$secret" \
            --auto-discover-url ${lib.escapeShellArg cfg.oidc.pocketId.discoveryUrl}
        else
          forgejo admin auth add-oauth \
            --name "$name" \
            --provider openidConnect \
            --key ${lib.escapeShellArg cfg.oidc.pocketId.clientId} \
            --secret "$secret" \
            --auto-discover-url ${lib.escapeShellArg cfg.oidc.pocketId.discoveryUrl}
        fi
      '';
    };
  };
}
