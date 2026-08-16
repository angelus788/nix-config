{ config, inputs, ... }: {
  age.secrets = {
      tailscaleAuthKey = {
        file = ../../secrets/tailscale-authkey.age;
        owner = config.home.username;
      };

      syncthing-cert = {
        file = ${inputs.secrets}/syncthing-cert-steamdeck.age;
        path = "${config.home.homeDirectory}/.config/syncthing/cert.pem";
      };

      syncthing-key = {
        file = ${inputs.secrets}/syncthing-key-steamdeck.age;
        path = "${config.home.homeDirectory}/.config/syncthing/key.pem";
      };
  };

  home.file.".config/syncthing/.keep".text = "";
}
