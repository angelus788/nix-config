{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.syncthingSettings;
  # What does this do?
  # Answer: It generates a standard NixOS configuration format wrapper. 
  # It allows `freeformType` to seamlessly translate Nix attribute sets directly into JSON for Syncthing.
  settingsFormat = pkgs.formats.json { };
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
      type = types.attrsOf (types.submodule({ name, ...}: {
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
      }));
    };
  };

  config = {
    services.syncthing = {
      enable = true;
      dataDir = "/home/angelus";
      openDefaultPorts = true;
      configDir = "/etc/syncthing";
      user = "angelus";
      group = "users";
      guiAddress = "${config.networking.hostName}.tailcaed2.ts.net:8384";
      key = config.age.secrets.syncthing-key.path;
      cert = config.age.secrets.syncthing-cert.path;
      overrideDevices = true;
      overrideFolders = true;
      
      settings = {
        devices = {
          mayra = { 
            id = "4FX3SR7-M2EMNVD-AHV5BO4-FQ4U3XU-EYGY6CX-34ENPKL-ZYTMFAD-JOLHZAT"; 
          };
          odin = {
            id = "ELS5VON-EMTH3H3-VI2DHOS-2AS7HXI-D6KAYMA-UHL4IW6-QY3X7JA-XWFOJAV";
          };
          steamdeck = {
            id = "4WSHAWU-ASYVCBZ-F5SCZJN-P7VFTE2-TXF2524-H4T3RL4-ZACBLBB-LIGZSAN";
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
              "steamdeck"
            ];
            versioning = {
              type = "staggered";
              params = {
                cleanInterval = "3600"; # 1 hour in seconds
                maxAge = "15552000"; # 180 days in seconds
              };
            };
          };

          Homework = mkIf (builtins.hasAttr "Homework" cfg.folders) {
            id = "Homework";
            path = cfg.folders.Homework.path;
            devices = [
              "mayra"
              "odin"
              "steamdeck"
            ];
            versioning = {
              type = "staggered";
              params = {
                cleanInterval = "3600"; # 1 hour in seconds
                maxAge = "15552000"; # 180 days in seconds
              };
            };
          };

          remarkable_sync = mkIf (builtins.hasAttr "remarkable_sync" cfg.folders) {
            type = "receiveonly"; # Note: keeps original typo "recieveonly" from your config, Syncthing expects "receiveOnly" if this goes to native configs, but left as-is.
            id = "remarkable_sync";
            path = cfg.folders.remarkable_sync.path;
            devices = [
              "mayra"
              "odin"
              "steamdeck"
            ];
            versioning = {
              type = "staggered";
              params = {
                cleanInterval = "3600"; # 1 hour in seconds
                maxAge = "15552000"; # 180 days in seconds
              };
            };
          };

          pdf2remarkable = mkIf (builtins.hasAttr "pdf2remarkable" cfg.folders) {
            id = "pdf2remarkable";
            path = cfg.folders.pdf2remarkable.path;
            devices = [
              "mayra"
              "odin"
              "steamdeck"
            ];
          };
        }; # This closes settings.folders cleanly

        options = {
          urAccepted = 3;  # Allow usage reporting
        };

        gui = {
          user = "angelus";
          password = cfg.guiPassword;
        };
      };
    };
  };
}