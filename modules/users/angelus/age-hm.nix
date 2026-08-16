# users/angelus/age-hm.nix
{ config, inputs, ... }: {
  age = {
    # Non-root identity fallbacks for standalone hosts
    identityPaths = [
      "${config.home.homeDirectory}/.ssh/angelus"
      "${config.home.homeDirectory}/.ssh/id_ed25519"
      "/var/lib/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    # Global user-level secrets shared across standalone machines
    secrets = {
      tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
    };
  };
}
