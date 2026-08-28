{
  config,
  lib,
  inputs,
  ...
}:
let
  service = "hermes-agent";
  cfg = config.homelab.services.${service};
in
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    ollamaModel = lib.mkOption {
      type = lib.types.str;
      default = "llama3.1:8b";
      description = ''
        Ollama model tag Hermes uses as its default LLM (CPU inference, so keep this small).
        Must support tool-calling — Nous Research's own "hermes3"/"hermes4" chat models do
        NOT (Hermes Agent itself detects and warns on this; see hermes_cli/model_switch.py
        upstream), despite the naming coincidence with this agent framework.
      '';
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "thor.thorsaga.net";
      description = "NetBird DNS name the Hermes dashboard binds to and is reachable at directly over the overlay (no TLS - NetBird has no client-side cert-minting equivalent to Tailscale's, but the transport is already WireGuard-encrypted)";
    };
    dashboardAuthEnvironmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        EnvironmentFile providing HERMES_DASHBOARD_BASIC_AUTH_USERNAME/_PASSWORD/_SECRET.
        Required: Hermes refuses to bind to anything but loopback without an
        auth provider configured, and this module binds to the NetBird DNS
        name (see `url`).
      '';
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Hermes";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Self-improving AI agent framework (Nous Research)";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "mdi-robot-happy";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Tools";
    };
  };

  config = lib.mkIf cfg.enable {
    # Local CPU-only inference backend for Hermes; not exposed outside loopback.
    services.ollama = {
      enable = true;
      host = "127.0.0.1";
      port = 11434;
      loadModels = [ cfg.ollamaModel ];
    };

    # Lets the interactive user read the shared HERMES_HOME state (owned by
    # the dedicated hermes user/group) so the CLI works over SSH, matching
    # what the upstream module does automatically for container.hostUsers.
    users.users.angelus.extraGroups = [ config.services.hermes-agent.group ];

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      environment.OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      settings.model.default = "ollama/${cfg.ollamaModel}";
      environmentFiles = lib.optional (
        cfg.dashboardAuthEnvironmentFile != null
      ) cfg.dashboardAuthEnvironmentFile;
      backend = {
        mode = "dashboard";
        # Hermes refuses non-loopback binds without an auth provider (see
        # dashboardAuthEnvironmentFile) and rejects requests whose Host header
        # doesn't match the bind target — binding to the NetBird DNS name
        # makes both checks agree with what clients actually connect to.
        host = cfg.url;
        waitFor = "hostname";
        port = 9119;
      };
    };
  };
}
