{
  config,
  lib,
  ...
}:
let
  service = "pocket-id";
  cfg = config.homelab.services.${service};
  hl = config.homelab;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable Pocket ID - lightweight passkey-based OIDC provider, run as an emergency-failover identity provider for when Keycloak (odin) is unreachable";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/opt/services/pocket-id";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "id.${hl.baseDomain}";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Pocket ID";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Passkey-based OIDC provider (Keycloak failover)";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "pocket-id.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "pocket-id" ];
    };
    encryptionKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to an agenix-decrypted file containing just the raw
        `ENCRYPTION_KEY` value (generate with `openssl rand -base64 32`, no
        `ENCRYPTION_KEY=` prefix - services.pocket-id.credentials passes the
        file's content verbatim as the variable's value, unlike a normal
        `KEY=value` env-file). Mandatory since Pocket ID v2 - the service
        refuses to start without it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.pocket-id = {
      enable = true;
      dataDir = cfg.dataDir;
      credentials.ENCRYPTION_KEY = cfg.encryptionKeyFile;
      settings = {
        APP_URL = "https://${cfg.url}";
        TRUST_PROXY = true;
      };
    };

    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:1411
      '';
    };
  };
}
