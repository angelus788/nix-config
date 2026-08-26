{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  gitAddress = "git.avgtechguy.com";
  gitPort = 69;
  repoUrl = "ssh://forgejo@${gitAddress}:${toString gitPort}/avgtechguy/nix-config.git";
  sshKeyPath = "/persist/ssh/ssh_host_ed25519_key";
in
{
  # 1. Declaratively register SSH options & host keys
  programs.ssh = {
      knownHosts = {
        "[${gitAddress}]:${toString gitPort}" = {
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyEZdau0EtGRmwJoS3CZTYpet6gXgu47QrNgbMEy8aJ";
        };
        "github.com" = {
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };
      };
    };

    # 2. Git global configuration
    programs.git = {
      enable = true;
      config = {
        # Redirects SSH requests for GitHub to HTTPS so public inputs never prompt for SSH keys
        url."https://github.com/".insteadOf = "git@github.com:";
      };
    };

  system.stateVersion = "25.11";

  # 2. Fully declarative upgrade service override
  systemd.services.nixos-upgrade = {
    path = [ pkgs.git pkgs.openssh ];
    environment = {
      GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -i ${sshKeyPath} -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes";
    };
    preStart = ''
      cd /etc/nixos
      ${pkgs.git}/bin/git config --global --add safe.directory /etc/nixos

      # Force origin remote to point strictly to Forgejo
      if ! ${pkgs.git}/bin/git remote | grep -q "^origin$"; then
        ${pkgs.git}/bin/git remote add origin "${repoUrl}"
      else
        ${pkgs.git}/bin/git remote set-url origin "${repoUrl}"
      fi

      ${pkgs.git}/bin/git fetch origin main
      ${pkgs.git}/bin/git reset --hard origin/main
    '';
  };

  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos#${config.networking.hostName}";
    flags = [
      "-L"
      "--accept-flake-config"
    ];
    dates = "Sat *-*-* 02:30:00";
    operation = "boot";
    allowReboot = true;
    rebootWindow = {
      lower = "02:30";
      upper = "05:00";
    };
  };

  imports = [
    ./filesystems
    ./nix
    "${inputs.secrets}/networks.nix"
  ];

  time.timeZone = "America/New_York";
    services.ntp.enable = true;

  users.users = {
    angelus = {
      hashedPasswordFile = config.age.secrets.hashedUserPassword.path;
    };
    root = {
      hashedPasswordFile = config.age.secrets.initialHashedPassword.path;
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
      initialHashedPassword.file = "${inputs.secrets}/initialHashedPassword.age";
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
    nixd
    nixpkgs-fmt
    inputs.agenix.packages."${stdenv.hostPlatform.system}".default
  ];

  nixpkgs.overlays = [
    # Existing unstable overlay
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config = prev.config // {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-39.8.10" ];
        };
      };

      beets = final.unstable.beets;

      # Self-hosted netbird stack pinned on 26.05 stable was stuck on 0.71.4, which
      # predates a breaking signal-protocol change (removal of the legacy Hello
      # handshake in v0.74.7) that current netbird clients require - peers could
      # never complete ICE/relay negotiation against it. Pull the whole netbird
      # family from unstable so client, server, and dashboard versions stay in sync.
      netbird = final.unstable.netbird;
      netbird-management = final.unstable.netbird-management;
      netbird-signal = final.unstable.netbird-signal;
      netbird-dashboard = final.unstable.netbird-dashboard;
    })

    # 2. Universal fetchurl override for uppush 2.5.0
    (final: prev: {
      fetchurl = args:
        let
          urlStr =
            if builtins.isAttrs args then
              args.url or (if (args ? urls && builtins.length args.urls > 0) then builtins.head args.urls else "")
            else if builtins.isString args then
              args
            else
              "";
        in
        if builtins.isString urlStr && builtins.match ".*uppush.*2\\.5\\.0.*" urlStr != null then
          prev.fetchurl (
            (if builtins.isAttrs args then args else { url = args; }) // {
              hash = "sha256-SRRFA1nQk0OsCm+FEaEN32bDTNCbcKyM0ZOhy5yXUEc=";
            }
          )
        else
          prev.fetchurl args;
    })
  ];
}