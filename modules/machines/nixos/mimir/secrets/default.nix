{ lib, inputs, ... }:
{
  age.secrets = {
    tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";
    wireguardPrivateKeyMimir = lib.mkDefault {
      owner = "systemd-network";
      file = "${inputs.secrets}/wireguardPrivateKeyMimir.age";
    };
  };
}
