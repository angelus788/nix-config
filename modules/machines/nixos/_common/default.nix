{ inputs
, config
, pkgs
, lib
, ...
}:

{
  programs.ssh =
    #COMEBACKTOTHIS
    let
      gitAddress = "git.avgtechguy.com";
    in
    {

      knownHosts = {
        "github.com".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII07ukuUm57yQYo2YL8GSLtPU8z9Q0NdU28d49wdoxbw";
        "[${gitAddress}]:69".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII07ukuUm57yQYo2YL8GSLtPU8z9Q0NdU28d49wdoxbw";
      };
      extraConfig = ''
        Host github.com
          User angelus
          IdentityFile /persist/ssh/ssh_host_ed25519_key
          IdentitiesOnly yes
          Host *
            IdentityAgent ~/.1password/agent.sock
          Host *
            ControlMaster no
            ControlPersist no
            ControlPath none
              IdentityFile /persist/ssh/ssh_host_ed25519_key
              IdentitiesOnly yes
              User forgejo
              Port 69
      '';
    };

  system.stateVersion = "25.11";

  systemd.services.nixos-upgrade.preStart = ''
    cd /etc/nixos
    chown -R root:root .
    git reset --hard HEAD
    git pull
  '';
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos#${config.networking.hostName}";
    flags = [
      "-L"
      "--accept-flake-config"
    ];
    dates = "Sat *-*-* 02:30:00";
    allowReboot = true;
  };

  imports = [
    ./filesystems
    ./nix
    #"${inputs.secrets}/networks.nix"
  ];

  time.timeZone = "America/New_York";

  users.users = {
    angelus = {
      hashedPasswordFile = config.age.secrets.hashedUserPassword.path;
    };
    root = {
      initialHashedPassword = config.age.secrets.hashedUserPassword.path;
    };
  };

  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      LoginGraceTime = 0;
      PermitRootLogin = "no";
    };
    ports = [ 69 ];
    hostKeys = [
      {
        path = "/persist/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/persist/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  programs.git.enable = true;
  programs.mosh.enable = true;
  programs.htop.enable = true;
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };

  age = {
    identityPaths = [
      "/persist/ssh/ssh_host_ed25519_key"
    ];
    secrets = {
      hashedUserPassword.file = "${inputs.secrets}/hashedUserPassword.age";
      #initialHashedPassword = "${inputs.secrets}/initialHashedPassword.age";
      smtpPassword = {
        file = "${inputs.secrets}/smtpPassword.age";
        owner = "angelus";
        group = "angelus";
        mode = "0440";
      };
    };

  };
  email = {
    enable = true;
    fromAddress = "myserver_announcements@mailbox.org";
    toAddress = "myserver_announcements@mailbox.org";
    smtpServer = "smtp.mailbox.org";
    smtpUsername = "myserver_announcements";
    smtpPasswordPath = config.age.secrets.smtpPassword.path;
  };

  security = {
    doas.enable = lib.mkDefault false;
    sudo = {
      enable = lib.mkDefault true;
      wheelNeedsPassword = lib.mkDefault false;
    };
  };

  homelab.motd.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    iperf3
    eza
    fastfetch
    tmux
    rsync
    iotop
    ncdu
    nmap
    jq
    ripgrep
    lm_sensors
    nixd # The Language Server
    nixpkgs-fmt # Optional: For auto-formatting
    inputs.agenix.packages."${stdenv.hostPlatform.system}".default
  ];


  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = prev.system;
        # Carry over your config (like allowUnfree) to the unstable set
        config = config.nixpkgs.config;
      };
    })
  ];

}
