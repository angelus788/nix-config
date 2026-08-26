{ inputs, pkgs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
    overlays = [
      # netbird pinned on 26.05 stable predates a breaking signal-protocol change
      # (v0.74.7 removed the legacy Hello handshake) that current clients require.
      # Keep this client in lockstep with the unstable-pinned server stack.
      (final: prev: {
        netbird = (import inputs.nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config = prev.config;
        }).netbird;
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
