{
  programs.ssh = {
    enable = true;
    # This silences the warning
    enableDefaultConfig = false;

    matchBlocks = {
      thor = {
        hostname = "thor";
        port = 69;
        user = "angelus";
        identityFile = "~/.ssh/angelus";
      };
      thorip = {
        hostname = "192.168.1.199";
        port = 69;
        user = "angelus";
        identityFile = "~/.ssh/angelus";
      };
      heimdall = {
        hostname = "heimdall";
        user = "angelus";
        port = 69;
        identityFile = "~/.ssh/angelus";
      };
      heimdallip = {
        hostname = "159.65.167.45";
        user = "angelus";
        port = 69;
        identityFile = "~/.ssh/angelus";
      };
      mayra = {
        hostname = "mayra";
        port = 69;
        identityFile = "~/.ssh/angelus";
      };
      mimir = {
        hostname = "192.168.1.251";
        user = "angelus";
        port = 22;
        identityFile = "~/.ssh/angelus";

      };
      mjolnir = {
        hostname = "mjolnir";
        port = 69;
        identityFile = "~/.ssh/angelus";
      };
      stormbreaker = {
        hostname = "stormbreaker";
        port = 69;
        identityFile = "~/.ssh/angelus";
      };
      odin = {
        hostname = "192.168.1.233";
        user = "angelus";
        port = 22;
        identityFile = "~/.ssh/angelus";
      };
      "github.com" = {
        user = "angelus788";
        port = 22;
        identityFile = "~/.ssh/angelus";
      };

    };
  };
}
