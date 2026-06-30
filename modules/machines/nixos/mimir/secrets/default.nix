{ lib, inputs, ... }:
{
  tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
  age.secrets.wireguardPrivateKeyMimir = lib.mkDefault {
    owner = "systemd-network";
    file = "${inputs.secrets}/wireguardPrivateKeyMimir.age";
  };
}
