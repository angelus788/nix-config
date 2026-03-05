{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
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
  }; # <--- This brace closes programs.vscode

  # This now lives at the top level of the module, where it belongs
  home.packages = with pkgs; [
    nixd
    nixpkgs-fmt
  ];
}
