{ config, inputs, ... }: {
  age.secrets = {

    syncthing-cert = {
      file = "${inputs.secrets}/syncthing-cert-steamdeck.age";
      path = "${config.home.homeDirectory}/.config/syncthing/cert.pem";
    };

    syncthing-key = {
      file = "${inputs.secrets}/syncthing-key-steamdeck.age";
      path = "${config.home.homeDirectory}/.config/syncthing/key.pem";
    };
  };

  home.file.".config/syncthing/.keep".text = "";
}
