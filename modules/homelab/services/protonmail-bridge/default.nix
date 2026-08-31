{ config, lib, pkgs, ... }:
let
  service = "protonmail-bridge";
  cfg = config.homelab.services.${service};
  overlayAddress = config.homelab.networks.overlay.${config.networking.hostName}.address;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };

    role = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
      default = "client"; 
    };
  };

  config =
    let
      mkIfElse =
        p: yes: no:
        lib.mkMerge [
          (lib.mkIf p yes)
          (lib.mkIf (!p) no)
        ];
    in
    mkIfElse (cfg.role == "client")
      (lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          pass
          gnupg
          protonmail-bridge
          socat # Added so we can bridge network interfaces
        ];

        environment.shellAliases = {
          protonmail-login = "systemctl --user stop ${service} && protonmail-bridge --cli && systemctl --user start ${service}";
        };

        # Automation script that initializes the pass/gpg vault seamlessly on boot
        systemd.user.services."${service}-init" = {
          description = "Bootstrap GPG and Pass vault for ProtonMail Bridge";
          wantedBy = [ "default.target" ];
          before = [ "${service}.service" ];
          
          path = with pkgs; [ gnupg pass coreutils gawk ];
          
          script = ''
            export PASSWORD_STORE_DIR="$HOME/.password-store"
            if ! gpg --list-keys "Proton Bridge" >/dev/null 2>&1; then
              gpg --batch --passphrase "" --quick-generate-key "Proton Bridge <bridge@internalnetwork.party>" rsa2048 sign,encrypt never
              KEY_ID=$(gpg --with-colons --list-keys "Proton Bridge" | awk -F: '/^fpr:/ {print $10; exit}')
              echo "$KEY_ID:6:" | gpg --import-ownertrust
              pass init "$KEY_ID"
            fi
          '';

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };

        # The core background service binding safely to localhost
        systemd.user.services.${service} = {
          description = "ProtonMail Bridge Service";
          wantedBy = [ "default.target" ];
          after = [ "network.target" "${service}-init.service" ];
          
          environment = {
            PASSWORD_STORE_DIR = "%h/.password-store";
          };

          path = with pkgs; [ pass gnupg ];

          serviceConfig = {
            Restart = "always";
            ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --log-level info";
          };
        };

      # Socat proxy for IMAP (Listens ONLY on the overlay VPN address, forwards to localhost)
        systemd.user.services."${service}-proxy-imap" = {
          description = "ProtonMail Bridge IMAP Overlay VPN Proxy";
          wantedBy = [ "default.target" ];
          after = [ "${service}.service" ];
          # The overlay VPN (netbird, a system service) may not have brought up
          # its interface/address yet when this user unit starts at boot — user
          # units can't reliably order after system units (After=/Wants= are a
          # no-op across that boundary), so retry patiently instead of racing it.
          startLimitIntervalSec = 300;
          startLimitBurst = 30;
          serviceConfig = {
            Restart = "always";
            RestartSec = 5;
            ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:1143,bind=${overlayAddress},fork,reuseaddr TCP4:127.0.0.1:1143";
          };
        };

        # Socat proxy for SMTP (Listens ONLY on the overlay VPN address, forwards to localhost)
        systemd.user.services."${service}-proxy-smtp" = {
          description = "ProtonMail Bridge SMTP Overlay VPN Proxy";
          wantedBy = [ "default.target" ];
          after = [ "${service}.service" ];
          startLimitIntervalSec = 300;
          startLimitBurst = 30;
          serviceConfig = {
            Restart = "always";
            RestartSec = 5;
            ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:1025,bind=${overlayAddress},fork,reuseaddr TCP4:127.0.0.1:1025";
          };
        };
      })
      {
        # Server role placeholder logic
      };
}