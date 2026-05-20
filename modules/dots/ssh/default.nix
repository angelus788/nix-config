{ inputs, ... }:
{
  imports = [
    "${inputs.secrets}/ssh.nix"
  ];
}
