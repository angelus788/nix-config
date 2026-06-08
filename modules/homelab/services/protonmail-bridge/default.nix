{ config, lib, pkgs, ... }:
let
  service = "protonmail-bridge";
  cfg = config.homelab.services.${service};
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "100.94.78.77";
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "ProtonMail Bridge";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Local IMAP/SMTP bridge for ProtonMail";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "proton-mail-bridge.svg"; 
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
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
              gpg --batch --passphrase "" --quick-generate-key "Proton Bridge <bridge@internalnetwork.party>" rsa2048 default never
              KEY_ID=$(gpg --list-keys --keyid-format LONG "Proton Bridge" | awk '/pub/ {split($2, a, "/"); print a[2]}')
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

          serviceConfig = {
            Restart = "always";
            ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --log-level info";
          };
        };

      # Socat proxy for IMAP (Listens ONLY on Tailscale IP, forwards to localhost)
        systemd.user.services."${service}-proxy-imap" = {
          description = "ProtonMail Bridge IMAP Tailscale Proxy";
          wantedBy = [ "default.target" ];
          after = [ "${service}.service" ];
          serviceConfig = {
            Restart = "always";
            # Changed TCP4-LISTEN:1143 to TCP4-LISTEN:1143,bind=100.94.78.77
            ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:1143,bind=100.94.78.77,fork,reuseaddr TCP4:127.0.0.1:1143";
          };
        };

        # Socat proxy for SMTP (Listens ONLY on Tailscale IP, forwards to localhost)
        systemd.user.services."${service}-proxy-smtp" = {
          description = "ProtonMail Bridge SMTP Tailscale Proxy";
          wantedBy = [ "default.target" ];
          after = [ "${service}.service" ];
          serviceConfig = {
            Restart = "always";
            # Changed TCP4-LISTEN:1025 to TCP4-LISTEN:1025,bind=100.94.78.77
            ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:1025,bind=100.94.78.77,fork,reuseaddr TCP4:127.0.0.1:1025";
          };
        };
      })
      {
        # Server role placeholder logic
      };
}