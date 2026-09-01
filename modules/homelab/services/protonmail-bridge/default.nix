{ config, lib, pkgs, ... }:
let
  service = "protonmail-bridge";
  cfg = config.homelab.services.${service};
  overlayAddress = config.homelab.networks.overlay.${config.networking.hostName}.address;

  # Bridge only ever issues a certificate for 127.0.0.1 (it's designed for
  # strictly-local use), so mail clients connecting via the overlay address
  # always see a hostname mismatch, no matter how many times you accept it.
  # Each proxy is a two-hop stunnel relay instead of a raw socat pipe:
  # the front hop terminates STARTTLS towards the mail client using our own
  # cert (correctly issued for overlayAddress), and the back hop re-initiates
  # STARTTLS towards bridge's real 127.0.0.1 listener, trusting its
  # self-signed cert since that leg never leaves the host.
  # A real filesystem path is required here (not the systemd "%h" specifier):
  # this same path is embedded verbatim in the stunnel config file below,
  # which stunnel reads directly with no specifier/variable expansion.
  certDir = "/var/lib/${service}-proxy";
  certPath = "${certDir}/proxy.pem";

  mkStunnelConf =
    {
      name,
      protocol,
      port,
      hopPort,
    }:
    pkgs.writeText "${service}-proxy-${name}-stunnel.conf" ''
      foreground = yes
      pid =

      [${name}-front]
      accept = ${overlayAddress}:${toString port}
      connect = 127.0.0.1:${toString hopPort}
      cert = ${certPath}
      protocol = ${protocol}
      client = no

      [${name}-back]
      accept = 127.0.0.1:${toString hopPort}
      connect = 127.0.0.1:${toString port}
      protocol = ${protocol}
      client = yes
      verify = 0
    '';
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
        systemd.tmpfiles.rules = [
          "d ${certDir} 0700 angelus angelus - -"
        ];

        environment.systemPackages = with pkgs; [
          pass
          gnupg
          protonmail-bridge
          openssl
          stunnel
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
            # protonmail-bridge.service touches the same GPG keybox concurrently at
            # boot, so a single --list-keys check can lose the lock race and report
            # a false "not found" here; retry before concluding the key is missing.
            key_exists=0
            for _ in 1 2 3 4 5; do
              if gpg --list-keys "Proton Bridge" >/dev/null 2>&1; then
                key_exists=1
                break
              fi
              sleep 2
            done
            if [ "$key_exists" = 0 ]; then
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

        # Generates a stable, long-lived self-signed cert for overlayAddress the
        # first time it runs; later boots reuse it so mail clients that already
        # accepted it don't need to re-accept it on every restart.
        systemd.user.services."${service}-proxy-cert-init" = {
          description = "Generate TLS certificate for ProtonMail Bridge overlay proxies";
          wantedBy = [ "default.target" ];
          before = [
            "${service}-proxy-imap.service"
            "${service}-proxy-smtp.service"
          ];
          path = [ pkgs.openssl pkgs.coreutils ];
          script = ''
            mkdir -p ${certDir}
            if [ ! -f ${certPath} ]; then
              openssl req -x509 -newkey rsa:2048 -nodes \
                -keyout ${certDir}/key.pem -out ${certDir}/cert.pem -days 3650 \
                -subj "/CN=${overlayAddress}" -addext "subjectAltName=IP:${overlayAddress}"
              cat ${certDir}/key.pem ${certDir}/cert.pem > ${certPath}
            fi
          '';
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };

        # STARTTLS-terminating proxy for IMAP (listens ONLY on the overlay VPN
        # address with a cert valid for it, re-establishes STARTTLS to bridge).
        systemd.user.services."${service}-proxy-imap" = {
          description = "ProtonMail Bridge IMAP Overlay VPN Proxy";
          wantedBy = [ "default.target" ];
          after = [
            "${service}.service"
            "${service}-proxy-cert-init.service"
          ];
          # The overlay VPN (netbird, a system service) may not have brought up
          # its interface/address yet when this user unit starts at boot — user
          # units can't reliably order after system units (After=/Wants= are a
          # no-op across that boundary), so retry patiently instead of racing it.
          startLimitIntervalSec = 300;
          startLimitBurst = 30;
          serviceConfig = {
            Restart = "always";
            RestartSec = 5;
            ExecStart = "${pkgs.stunnel}/bin/stunnel ${
              mkStunnelConf {
                name = "imap";
                protocol = "imap";
                port = 1143;
                hopPort = 41430;
              }
            }";
          };
        };

        # STARTTLS-terminating proxy for SMTP (listens ONLY on the overlay VPN
        # address with a cert valid for it, re-establishes STARTTLS to bridge).
        systemd.user.services."${service}-proxy-smtp" = {
          description = "ProtonMail Bridge SMTP Overlay VPN Proxy";
          wantedBy = [ "default.target" ];
          after = [
            "${service}.service"
            "${service}-proxy-cert-init.service"
          ];
          startLimitIntervalSec = 300;
          startLimitBurst = 30;
          serviceConfig = {
            Restart = "always";
            RestartSec = 5;
            ExecStart = "${pkgs.stunnel}/bin/stunnel ${
              mkStunnelConf {
                name = "smtp";
                protocol = "smtp";
                port = 1025;
                hopPort = 41431;
              }
            }";
          };
        };
      })
      {
        # Server role placeholder logic
      };
}