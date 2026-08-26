{ pkgs
, config
, inputs
, ...
}:

{
  # 1. Enable the nix-darwin NetBird background service
  services.netbird.enable = true;

  # 2. Expose NetBird CLI package in environment
  environment.systemPackages = [ pkgs.netbird ];

  # 3. Decrypt your Agenix secret
  age.secrets.netbirdSetupKey.file = "${inputs.secrets}/netbirdSetupKey.age";

  # 4. Automated LaunchDaemon for zero-touch configuration
  launchd.daemons.netbird-autoconfig = {
    script = ''
      set -e

      # Wait for the netbird socket/daemon to become active
      for i in {1..30}; do
        if ${pkgs.netbird}/bin/netbird status >/dev/null 2>&1; then
          break
        fi
        sleep 1
      done

      # Wait for the agenix secret to be decrypted/mounted
      for i in {1..30}; do
        if [ -r ${config.age.secrets.netbirdSetupKey.path} ]; then
          break
        fi
        sleep 1
      done

      # Extract the decrypted key from Agenix
      SETUP_KEY=$(cat ${config.age.secrets.netbirdSetupKey.path})

      # Connect to NetBird using the setup key
      # Add --management-url if you are self-hosting NetBird
      ${pkgs.netbird}/bin/netbird up \
        --setup-key="$SETUP_KEY" \
        --management-url https://netbird.avgtechguy.com \
        --allow-server-ssh
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/netbird-autoconfig.log";
      StandardErrorPath = "/var/log/netbird-autoconfig.err";
    };
  };
}
