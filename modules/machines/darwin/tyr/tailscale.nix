{
  pkgs,
  config,
  inputs,
  ...
}:

{
  # 1. Enable the nix-darwin Tailscale background daemon
  services.tailscale.enable = true;

  # 2. Expose tailscale CLI package in environment
  environment.systemPackages = [ pkgs.tailscale ];

  # 3. Decrypt your Agenix secret (Adjust path to match your setup)
  age.secrets.tailscaleAuthKey.file = "${inputs.secrets}/tailscaleAuthKey.age";

  # 4. Automated LaunchDaemon for zero-touch configuration
  launchd.daemons.tailscale-autoconfig = {
    script = ''
      set -e

      for i in {1..30}; do
        if [ -S /var/run/tailscaled.socket ]; then
          break
        fi
        sleep 1
      done

      # Updated to camelCase attribute path
      AUTH_KEY=$(cat ${config.age.secrets.tailscaleAuthKey.path})

      ${pkgs.tailscale}/bin/tailscale up \
        --authkey="$AUTH_KEY" \
        --ssh \
        --accept-routes \
        --reset
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/tailscale-autoconfig.log";
      StandardErrorPath = "/var/log/tailscale-autoconfig.err";
    };
  };
}
