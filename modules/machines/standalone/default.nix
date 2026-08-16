{ lib, self, ... }:
let
  entries = builtins.attrNames (builtins.readDir ./.);
  configs = builtins.filter (dir: builtins.pathExists (./. + "/${dir}/home.nix")) entries;

  systemArchMap = {
    # "mac-laptop" = "aarch64-darwin";
  };

  userMap = {
    steamdeck = "deck";
    ubuntu = "angelus";
  };
in
{
  flake.homeConfigurations = lib.listToAttrs (
    builtins.map (
      name:
      let
        system = lib.attrsets.attrByPath [ name ] "x86_64-linux" systemArchMap;
        username = lib.attrsets.attrByPath [ name ] "angelus" userMap;
        homeDir = if lib.hasSuffix "-darwin" system then "/Users/${username}" else "/home/${username}";
        pkgs = self.inputs.nixpkgs.legacyPackages.${system};
      in
      lib.nameValuePair "${username}@${name}" (
        self.inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit (self) inputs;
          };

          modules = [
            # Base home-manager modules
            self.inputs.agenix.homeManagerModules.default
            self.inputs.nix-index-database.homeModules.nix-index

            # Relative to modules/machines/standalone (up 2 levels to modules/)
            ../../users/angelus/dots.nix
            #../../users/angelus/age.nix
            ../../users/angelus/age-hm.nix
            ../../dots/tmux

            # Global standalone configuration defaults
            {
              home.username = username;
              home.homeDirectory = homeDir;
              home.stateVersion = lib.mkDefault "26.05";
              programs.home-manager.enable = true;
              nix.package = pkgs.nix;
            }

            # Common standalone overrides (if present)
            (./. + "/_common/default.nix")

            # Host-specific standalone config
            (./. + "/${name}/home.nix")
          ];
        }
      )
    ) configs
  );
}
