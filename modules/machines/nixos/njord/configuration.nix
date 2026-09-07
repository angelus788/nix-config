{ pkgs
, lib
, config
, inputs
, ...
}:
let
  iot = config.homelab.networks.local.iot.reservations;
  #  tvIpAddress = iot.lgtv.Address;
  #  tvMacAddress = iot.lgtv.MACAddress;
  tvIpAddress = iot.samsungtv.Address;
  tvMacAddress = iot.samsungtv.MACAddress;
in
{

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
  '';

  # Upstream nixpkgs bug: netbird-ui's own .desktop Exec line is now
  # `env WEBKIT_DISABLE_DMABUF_RENDERER=1 netbird-ui`, but the netbird NixOS
  # module's wrapper still substitutes the literal `Exec=netbird-ui`, so
  # --replace-fail aborts the build with "pattern doesn't match". ui.enable
  # defaults to true on any host with a graphical session (plasma6 here) -
  # disable it until nixpkgs catches up. The CLI/daemon/tunnel work fine
  # without the tray icon.
  services.netbird.ui.enable = false;

  # Fronts the Syncthing GUI (loopback:8384, see modules/misc/syncthing)
  # with a real Let's Encrypt cert so it's reachable without :8384 - same
  # pattern as odin's kvm.thorsaga.net / odin-syncthing.thorsaga.net (see
  # modules/machines/nixos/odin/homelab/default.nix). Requires an Extra DNS
  # Label on this host's own NetBird peer (mayra-syncthing) - see
  # [[homelab_netbird_extra_dns_labels]] memory for why that needs a full
  # peer remove+re-register, not just `netbird up --extra-dns-labels`.
  security.acme = {
    acceptTerms = true;
    defaults.email = "avgtechguy@mailbox.org";
    certs."thorsaga.net" = {
      reloadServices = [ "caddy.service" ];
      domain = "thorsaga.net";
      extraDomainNames = [ "*.thorsaga.net" ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      group = config.services.caddy.group;
      environmentFile = config.age.secrets.cloudflareDnsApiCredentials.path;
    };
  };
  services.caddy = {
    enable = true;
    virtualHosts."njord-syncthing.thorsaga.net" = {
      useACMEHost = "thorsaga.net";
      extraConfig = ''
        reverse_proxy 127.0.0.1:8384
      '';
    };
  };
  networking.firewall.interfaces.${config.services.netbird.clients.default.interface}.allowedTCPPorts = [ 443 ];

  # Jovian vendors its own gamescope source (pinned to Valve's release tag,
  # e.g. 3.16.26) for SteamOS feature parity, but still inherits nixpkgs'
  # own gamescope patches/postPatch, which target wherever GetUsrDir() (the
  # function controlling where gamescope looks for its ReShade shaders)
  # lives in whatever *newer* gamescope version nixpkgs itself packages.
  # Checked upstream directly: at Valve's 3.16.26 tag, GetUsrDir() is
  # defined in src/Utils/DirHelpers.cpp returning a literal "/usr" - NOT in
  # src/reshade_effect_manager.cpp (shaders-path.patch's target, presumably
  # correct for some other gamescope version) and NOT already containing
  # nixpkgs' "@out@" placeholder (nixpkgs' own postPatch's target, also
  # presumably correct for a newer version). Both assumptions are wrong for
  # 3.16.26 specifically - dropping both and substituting the real "/usr"
  # literal in DirHelpers.cpp directly fixes it correctly for this version,
  # rather than just papering over the build failure.
  #
  # mkAfter: must run after jovian's own overlay (which re-vendors
  # gamescope's version/src but keeps nixpkgs' patches/postPatch) so this
  # actually sees and can override that result, regardless of import order.
  nixpkgs.overlays = lib.mkAfter [
    (_final: prev: {
      gamescope = prev.gamescope.overrideAttrs (old: {
        patches = builtins.filter
          (
            p: !(lib.strings.hasSuffix "shaders-path.patch" (toString p))
          )
          old.patches;
        postPatch = lib.replaceStrings [ ''--replace-fail "@out@" "$out"'' ] [ "" ]
          (
            old.postPatch or ""
          )
        + ''
          substituteInPlace src/Utils/DirHelpers.cpp \
            --replace-fail 'return "/usr";' 'return "$out";'
        '';
      });
    })
  ];

  imports = [
    #./hardware-configuration.nix
    ./secrets
    ../../../apps/openpuck
    ../../../misc/ryzen-undervolting
    ../../../misc/samsung-tv
    ../../../misc/syncthing
    ../../../misc/syncthing-settings
    ../../../misc/user-avatar
    ../../../apps/netbird
    #../../../misc/lgtv
    inputs.jovian.nixosModules.default
    #./lact.nix
    ./boot.nix
    ./no-rgb.nix
    ./disko.nix
  ];

  environment.systemPackages = [
    pkgs.firefox-bin
    pkgs.bitwarden-cli
    pkgs.bitwarden-desktop
    pkgs.google-chrome
    #pkgs.lutris #enable later on
    pkgs.s-tui
    pkgs.stress
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
    "electron-39.8.10"
  ];

  systemd.tmpfiles.rules = [
    "d /data/sda 0775 angelus angelus - -"
    "d /data/sdb 0775 angelus angelus - -"
  ];


  # fileSystems."/" = {
  #   device = "/dev/disk/by-id/nvme-CT1000P1SSD8_202629273359_1-part2";
  #   fsType = "ext4";
  # };
  # fileSystems."/boot" = {
  #   device = "/dev/disk/by-id/nvme-CT1000P1SSD8_202629273359_1-part1";
  #   fsType = "vfat";
  # };

  hardware = {
    bluetooth.enable = lib.mkForce false;
    bluetooth.powerOnBoot = false;
    enableRedistributableFirmware = true;
    xpadneo.enable = true;
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
    xone.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    openssh.enable = true;
    desktopManager.plasma6.enable = true;
    #lgtv = {
    #  enable = true;
    #  ipAddress = tvIpAddress;
    #  macAddress = tvMacAddress;
    #  user = "angelus";
    #  group = "angelus";
    #};
    samsungtv = {
      enable = false;
      ipAddress = tvIpAddress;
      macAddress = tvMacAddress;
      hdmiInput = "HDMI1";
      user = "angelus";
      group = "angelus";
    };
    ryzen-undervolting = {
      enable = true;
      offset = -25;
    };
  };

  networking = {
    networkmanager.enable = true;
    hostName = "njord";
    hostId = "8425e349";
    interfaces.enp2s0.wakeOnLan = {
      #might need to be replaced as well
      #enp4s0
      enable = true;
    };
  };

  jovian = {
    hardware = {
      has.amd.gpu = true;
      amd.gpu.enableBacklightControl = false;
    };
    steam = {
      updater.splash = "vendor";
      enable = true;
      autoStart = true;
      user = "angelus";
      desktopSession = "plasma";
    };
    steamos = {
      useSteamOSConfig = true;
    };
    decky-loader = {
      enable = true;
      extraPackages = with pkgs; [
        curl
        unzip
        util-linux
        gnugrep
      ];
    };
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # Necessary for KMS display capture
    openFirewall = true; # Opens the default ports: 47984-48010
  };

  home-manager.users.angelus.myHomeDots.enableGui = true;
}
