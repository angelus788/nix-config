{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.syncthingSettings;
  settingsFormat = pkgs.formats.json { };
in
{
  options.syncthingSettings = {
    guiPassword = mkOption {
      type = types.str;
      description = ''
        Password to the web GUI
        ENSURE THIS IS A BCRYPT ENCRYPTED PASSWORD
      '';
    };
    folders = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        freeformType = settingsFormat.type;
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            description = "The name of the folder";
          };
          path = mkOption {
            type = types.str;
            description = "The path to keep the folder";
          };
        };
      }));
    };
  };

  config = {
    # Home Manager Syncthing User Service
    services.syncthing = {
      enable = true;

      # Maps to Home Manager's services.syncthing.settings structure
      settings = {
        gui = {
          user = config.home.username;
          password = cfg.guiPassword;
          address = "127.0.0.1:8384";
          insecureSkipHostcheck = true;
        };

        devices = {
          mayra = { id = "4FX3SR7-M2EMNVD-AHV5BO4-FQ4U3XU-EYGY6CX-34ENPKL-ZYTMFAD-JOLHZAT"; };
          mjolnir = { id = "BGC2RDL-CNAFJHL-SKWNQXE-VBRC476-4PO2SGZ-CQIGYS7-WQ2TBV2-5X72JQV"; };
          odin = { id = "ELS5VON-EMTH3H3-VI2DHOS-2AS7HXI-D6KAYMA-UHL4IW6-QY3X7JA-XWFOJAV"; };
          steamdeck = { id = "4WSHAWU-ASYVCBZ-F5SCZJN-P7VFTE2-TXF2524-H4T3RL4-ZACBLBB-LIGZSAN"; };
          stormbreaker = { id = "REPLACE"; };
        };

        folders = {
          d2r-offline-saves = mkIf (builtins.hasAttr "d2r-offline-saves" cfg.folders) {
            id = "d2r-offline-saves";
            path = cfg.folders.d2r-offline-saves.path;
            devices = [ "mayra" "odin" "steamdeck" ];
            versioning = { type = "simple"; params = { keep = "5"; }; };
            ignorePatterns = [ "Settings.json" "*.key" ];
          };

          Documents = mkIf (builtins.hasAttr "Documents" cfg.folders) {
            id = "Documents";
            path = cfg.folders.Documents.path;
            devices = [ "mayra" "odin" "mjolnir" "stormbreaker" ];
            versioning = {
              type = "staggered";
              params = { cleanInterval = "3600"; maxAge = "15552000"; };
            };
          };

          Homework = mkIf (builtins.hasAttr "Homework" cfg.folders) {
            id = "Homework";
            path = cfg.folders.Homework.path;
            devices = [ "mayra" "mjolnir" "odin" "stormbreaker" ];
            versioning = {
              type = "staggered";
              params = { cleanInterval = "3600"; maxAge = "15552000"; };
            };
          };

          remarkable_sync = mkIf (builtins.hasAttr "remarkable_sync" cfg.folders) {
            type = "receiveonly";
            id = "remarkable_sync";
            path = cfg.folders.remarkable_sync.path;
            devices = [ "mayra" "mjolnir" "odin" "stormbreaker" ];
            versioning = {
              type = "staggered";
              params = { cleanInterval = "3600"; maxAge = "15552000"; };
            };
          };

          pdf2remarkable = mkIf (builtins.hasAttr "pdf2remarkable" cfg.folders) {
            id = "pdf2remarkable";
            path = cfg.folders.pdf2remarkable.path;
            devices = [ "mayra" "mjolnir" "odin" "stormbreaker" ];
          };
        };

        options = {
          urAccepted = 3;
        };
      };
    };
  };
}
