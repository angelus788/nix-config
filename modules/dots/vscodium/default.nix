{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHomeDots.enableGui {
  programs.vscode = {
    enable = true;
    #package = pkgs.vscodium; # Tells the module to install VSCodium instead of VS Code

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        arcticicestudio.nord-visual-studio-code
      ];

      userSettings = {
        # Use nixd as the LSP
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.serverSettings" = {
          "nixd" = {
            "formatting" = {
              "command" = [ "nixpkgs-fmt" ];
            };
            "options" = {
              "nixos" = {
                "expr" = "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.mjolnir.options";
              };
            };
          };
        };

        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.formatOnSave" = true;
        };

        "telemetry.enableTelemetry" = false;
        "update.mode" = "none";
      };
    };
  };

  home.packages = with pkgs; [
    nixd
    nixpkgs-fmt
  ];
  };
}
