{ pkgs, ... }:
{

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
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
            # This enables autocomplete for NixOS options
            "nixos" = {
              "expr" = "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.mjolnir.options";
            };
          };
        };
      };

      # Set nixpkgs-fmt as the default formatter for Nix files
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
        "editor.formatOnSave" = true;
      };

      # General VSCodium Polish
      "telemetry.enableTelemetry" = false;
      "update.mode" = "none";
    };
  };

  # Ensure the LSP and Formatter are available in your path
  home.packages = with pkgs; [
    nixd
    nixpkgs-fmt
  ];
}
