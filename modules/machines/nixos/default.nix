{ lib
, self
, ...
}:
let
  entries = builtins.attrNames (builtins.readDir ./.);
  configs = builtins.filter (dir: builtins.pathExists (./. + "/${dir}/configuration.nix")) entries;
  homeManagerCfg = userPackages: extraImports: {
    home-manager.useGlobalPkgs = false;
    home-manager.extraSpecialArgs = {
      inherit (self) inputs;
    };
    home-manager.users.angelus.imports = [
      self.inputs.agenix.homeManagerModules.default
      self.inputs.nix-index-database.homeModules.nix-index
      self.inputs.nixvim.homeModules.nixvim
      ../../users/angelus/dots.nix
      ../../users/angelus/age.nix
      ../../dots/tmux
      ../../dots/nvim
    ]
    ++ extraImports;
    home-manager.backupFileExtension = "bak";
    home-manager.useUserPackages = userPackages;
  };
in
{

  flake.nixosConfigurations =
    let
      nixpkgsMap = {
        mayra = "-unstable";
      };
      systemArchMap = {
        mona = "aarch64-linux";
      };
      myNixosSystem =
        name: self.inputs."nixpkgs${lib.attrsets.attrByPath [ name ] "" nixpkgsMap}".lib.nixosSystem;
    in
    lib.listToAttrs (
      builtins.map
        (
          name:
          lib.nameValuePair name (
            (myNixosSystem name) {
              system = lib.attrsets.attrByPath [ name ] "x86_64-linux" systemArchMap;
              specialArgs = {
                inherit (self) inputs;
                self = {
                  nixosModules = self.nixosModules;
                };
              };

              modules = [
                ../../homelab
                ../../misc/email
                #../../misc/tg-notify
                #../../misc/mover
                #../../misc/withings2intervals
                self.inputs.agenix.nixosModules.default
                self.inputs.disko.nixosModules.disko
                #self.inputs.adios-bot.nixosModules.default
                self.inputs.autoaspm.nixosModules.default
                #self.inputs.invoiceplane.nixosModules.default
                self.inputs."home-manager${
                lib.attrsets.attrByPath [ name ] "" nixpkgsMap
              }".nixosModules.home-manager
                (./. + "/_common/default.nix")
                (./. + "/${name}/configuration.nix")
                ../../users/angelus
                (homeManagerCfg false [ ])
              ];
            }
          )
        )
        configs
    );
}
