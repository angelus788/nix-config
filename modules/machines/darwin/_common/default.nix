{ pkgs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
    overlays = [
      (_self: super: {
        nodejs = super.nodejs_22;

      })
    ];
  };


  nix = {
    settings = {
      max-jobs = "auto";
      trusted-users = [
        "root"
        "angelus"
        "@admin"
      ];
    };
  };

  imports = [ ./nix ];

  environment.systemPackages = with pkgs; [
    nixd # The Language Server
    nixpkgs-fmt # Optional: For auto-formatting
    tmux
  ];

}
