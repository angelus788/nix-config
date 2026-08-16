{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.syncthingSettings;
  settingsFormat = pkgs.formats.json { };
  nodeName = config.networking.hostName;
  fqdn = "${nodeName}.tailcaed2.ts.net";
in
{
  options.syncthingSettings = {
    guiPassword = mkOption {
      type = types.str;
      description = mdDoc ''
        Password to the web GUI
        ENSURE THIS IS A BCRYPT ENCRYPTED PASSWORD
      '';
    };
    folders = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }: {
            freeformType = settingsFormat.type;
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                description = mdDoc ''
                  The name of the folder as specified in `modules/misc/syncthing/default.nix`
                '';
              };
              path = mkOption {
                type = types.str;
                description = mdDoc ''
                  The path to keep the folder
                '';
              };
            };
          }
        )
      );
    };
  };

  config = {
    # 1. Bind local Syncthing GUI strictly to loopback
    services.syncthing = {
      enable = true;
      dataDir = "/home/angelus";
      openDefaultPorts = true;
      configDir = "/etc/syncthing";
      user = "angelus";
      group = "users";
      guiAddress = "127.0.0.1:8384";
      key = config.age.secrets.syncthing-key.path;
      cert = config.age.secrets.syncthing-cert.path;
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = {
          mayra = {
            id = "4FX3SR7-M2EMNVD-AHV5BO4-FQ4U3XU-EYGY6CX-34ENPKL-ZYTMFAD-JOLHZAT";
          };
          mjolnir = {
            id = "BGC2RDL-CNAFJHL-SKWNQXE-VBRC476-4PO2SGZ-CQIGYS7-WQ2TBV2-5X72JQV";
          };
          odin = {
            id = "ELS5VON-EMTH3H3-VI2DHOS-2AS7HXI-D6KAYMA-UHL4IW6-QY3X7JA-XWFOJAV";
          };
          steamdeck = {
            id = "TRLJTOR-TSIF4FB-JTDBBBX-BHMUHKE-5NL3JOX-JKG3KV7-TT376A3-YSVHZQ3";
          };
          stormbreaker = {
            id = "TUKVJGF-LSXM5VC-XC5IY3D-7PQBJDB-N4NVPBO-NG5WJE4-FYJ54NT-TEPGIA6";
          };
          ubuntu = {
            id = "TJDO4ME-M7S7AVU-TOA66BJ-C47BVF3-AEMYC7Z-SM3RIPJ-5WXW3KD-LM4ISQI";
          };
        };

        folders = {
          d2r-offline-saves = mkIf (builtins.hasAttr "d2r-offline-saves" cfg.folders) {
            id = "d2r-offline-saves";
            path = cfg.folders.d2r-offline-saves.path;
            devices = [
              "mayra"
              "odin"
              "steamdeck"
            ];
            versioning = {
              type = "simple";
              params = {
                keep = "5";
              };
            };
            ignorePatterns = [
              "Settings.json"
              "*.key"
            ];
          };

          Documents = mkIf (builtins.hasAttr "Documents" cfg.folders) {
            id = "Documents";
            path = cfg.folders.Documents.path;
            devices = [
              "mayra"
              "odin"
              "mjolnir"
              "stormbreaker"
              "steamdeck"
              "ubuntu"
            ];
            versioning = {
              type = "staggered";
              params = {
                cleanInterval = "3600";
                maxAge = "15552000";
              };
            };
          };

          Homework = mkIf (builtins.hasAttr "Homework" cfg.folders) {
            id = "Homework";
            path = cfg.folders.Homework.path;
            devices = [
              "mayra"
              "mjolnir"
              "odin"
              "stormbreaker"
              "steamdeck"
              "ubuntu"
            ];
            versioning = {
              type = "staggered";
              params = {
                cleanInterval = "3600";
                maxAge = "15552000";
              };
            };
          };

          remarkable_sync = mkIf (builtins.hasAttr "remarkable_sync" cfg.folders) {
            type = "receiveonly";
            id = "remarkable_sync";
            path = cfg.folders.remarkable_sync.path;
            devices = [
              "mayra"
              "mjolnir"
              "odin"
              "stormbreaker"
              "steamdeck"
              "ubuntu"
            ];
            versioning = {
              type = "staggered";
              params = {
                cleanInterval = "3600";
                maxAge = "15552000";
              };
            };
          };

          pdf2remarkable = mkIf (builtins.hasAttr "pdf2remarkable" cfg.folders) {
            id = "pdf2remarkable";
            path = cfg.folders.pdf2remarkable.path;
            devices = [
              "mayra"
              "mjolnir"
              "odin"
              "stormbreaker"
              "steamdeck"
              "ubuntu"
            ];
          };
        };

        options = {
          urAccepted = 3;
        };

        gui = {
          user = "angelus";
          password = cfg.guiPassword;
          insecureSkipHostcheck = true;
        };
      };
    };

    # 2. Local Caddy instance per node
    services.caddy = {
      enable = true;
      virtualHosts."${config.networking.hostName}.tailcaed2.ts.net" = {
        extraConfig = ''
          tls {
            get_certificate tailscale
          }
          reverse_proxy 127.0.0.1:8384
        '';
      };
    };

    # 3. Allow Tailscale to issue certs to Caddy on this node
    services.tailscale.permitCertUid = "caddy";

    # Open local HTTP/HTTPS firewall ports
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
