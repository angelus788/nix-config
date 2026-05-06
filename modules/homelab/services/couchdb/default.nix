{ config
, lib
, pkgs
, ...
}:
let
  service = "couchdb";
  cfg = config.homelab.services.${service};
  hl = config.homelab;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable CouchDB for Livesync";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/opt/services/couchdb/data";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/opt/services/couchdb/etc";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "couchdb.${hl.baseDomain}";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "CouchDB";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "NoSQL Database";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "couchdb.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Databases";
    };
    admin.passwordFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to agenix secret containing COUCHDB_USER and COUCHDB_PASSWORD";
      # No default here ensures you don't forget to set it in your host config
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0775 ${hl.user} ${hl.group} - -"
      "d ${cfg.configDir} 0775 ${hl.user} ${hl.group} - -"
    ];

    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:5984
      '';
    };

    virtualisation = {
      podman.enable = true;
      oci-containers = {
        containers = {
          "couchdb-for-ols" = {
            image = "couchdb:latest";
            autoStart = true;
            ports = [
              "5984:5984"
            ];
            volumes = [
              "${cfg.dataDir}:/opt/couchdb/data"
              "${cfg.configDir}:/opt/couchdb/etc/local.d"
            ];
            # environmentFiles takes the path provided by agenix
            environmentFiles = [
              cfg.admin.passwordFile
            ];
            environment = { };
            extraOptions = [
              "--pull=newer"
            ];
          };
        };
      };
    };
  };
}
