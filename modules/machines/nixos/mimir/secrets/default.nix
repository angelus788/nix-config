{ lib, inputs, ... }:
{
  age.secrets.wireguardPrivateKeyMimir = lib.mkDefault {
    owner = "systemd-network";
    file = "${inputs.secrets}/wireguardPrivateKeyMimir.age";
  };
}
