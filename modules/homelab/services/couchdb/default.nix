{ config
, lib
, pkgs
, ...
}:
let
  service = "couchdb";
  cfg = config.homelab.services.${service};
  hl = config.homelab;
  containerName = "couchdb-for-ols";
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
      # Point this to "/run/agenix/couchdb-password" in your host config
      description = "Path to agenix secret containing COUCHDB_PASSWORD=value";
    };
  };

  config = lib.mkIf cfg.enable {
    # 1. Directory Setup (Using CouchDB's internal UID 5984)
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0775 5984 5984 - -"
      "d ${cfg.configDir} 0775 5984 5984 - -"
    ];

    # 2. Automated Initialization Service
    systemd.services."init-couchdb" = {
      description = "Initialize CouchDB system databases";
      after = [ "podman-${containerName}.service" ];
      # Use partOf so init doesn't fail if the container restarts
      partOf = [ "podman-${containerName}.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "10s";
      };

      script = ''
        # 1. Wait for CouchDB API to be responsive
        until ${pkgs.curl}/bin/curl -s http://127.0.0.1:5984/_up; do
          echo "Waiting for CouchDB at ${containerName} to start..."
          sleep 2
        done

        # 2. Extract password from agenix secret
        # Assuming the file looks like COUCHDB_PASSWORD=yourpass
        PASS=$(${pkgs.coreutils}/bin/cat ${cfg.admin.passwordFile} | ${pkgs.gnused}/bin/sed 's/COUCHDB_PASSWORD=//')

        # 3. Create required system databases
        for db in _users _replicator _global_changes; do
          echo "Initializing database: $db"
          ${pkgs.curl}/bin/curl -s -X PUT \
            -u "admin:$PASS" \
            http://127.0.0.1:5984/$db
        done

        # 4. Finalize the single-node setup
        echo "Finalizing cluster setup..."
        ${pkgs.curl}/bin/curl -s -X POST -H "Content-Type: application/json" \
          -u "admin:$PASS" \
          http://127.0.0.1:5984/_cluster_setup \
          -d '{"action": "finish_cluster"}'
      '';
    };

    # 3. Reverse Proxy
    services.caddy.virtualHosts."${cfg.url}" = {
      useACMEHost = hl.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:5984
      '';
    };

    # 4. Podman Container Definition
    virtualisation.oci-containers.containers."${containerName}" = {
      image = "couchdb:latest";
      autoStart = true;
      ports = [ "127.0.0.1:5984:5984" ];
      volumes = [
        "${cfg.dataDir}:/opt/couchdb/data"
        "${cfg.configDir}:/opt/couchdb/etc/local.d"
      ];

      environment = {
        COUCHDB_USER = "admin";
      };

      extraOptions = [
        "--pull=newer"
        # We pass the agenix file directly to Podman to handle the env injection
        "--env-file=${cfg.admin.passwordFile}"
      ];
    };
  };
}
