{ config
, inputs
, ...
}:

{
  # NetBird via Homebrew instead of nixpkgs: the nixpkgs `netbird-ui` package
  # can't build on Darwin (its wails3 dependency pulls in webkitgtk, which is
  # unconditionally marked broken on Darwin upstream). The official app
  # bundle gives us the real menu-bar tray icon, at the cost of the daemon
  # and CLI living outside Nix's control (installed/managed by Homebrew +
  # launchctl, not nix-darwin).
  #
  # No manual `brew trust` step needed: nix-darwin's homebrew module always
  # emits `trusted: true` in the generated Brewfile, and `brew bundle`
  # resolves that straight into Homebrew's trust store for fully-qualified
  # names (see Homebrew::Bundle::Trust), which covers the "untrusted tap"
  # refusal this would otherwise hit on first install. The cask's
  # `depends_on formula: "netbird"` resolves to netbirdio/tap/netbird, so
  # that formula needs its own trusted Brewfile entry too -- trust isn't
  # inherited through a dependency, only entries actually listed here get
  # one.

  homebrew.taps = [ "netbirdio/tap" ];
  homebrew.brews = [ "netbirdio/tap/netbird" ];
  homebrew.casks = [ "netbirdio/tap/netbird-ui" ];

  # Decrypt the Agenix setup-key secret (same secret used by the nixpkgs-based
  # darwin_apps/netbird.nix, kept for easy A/B swap between the two).
  age.secrets.netbirdSetupKey.file = "${inputs.secrets}/netbirdSetupKey.age";

  # Automated zero-touch connect, using the Homebrew-installed `netbird` CLI
  # (from the netbirdio/tap `netbird` formula), which talks to the
  # cask-installed system LaunchDaemon at /Library/LaunchDaemons/netbird.plist
  # -- NOT the nixpkgs netbird binary/daemon.
  launchd.daemons.netbird-autoconfig = {
    script = ''
      set -e

      NETBIRD_BIN="/opt/homebrew/bin/netbird"

      # This LaunchDaemon loads (RunAtLoad) as part of darwin-rebuild
      # activation, which races the `brew bundle` step that actually
      # installs the netbird formula -- on a fresh/updated install the
      # binary may not exist yet when this script first runs. Wait for the
      # binary itself before waiting for its daemon, generously (up to 5
      # minutes), since Homebrew installs can be slow.
      for i in $(seq 1 150); do
        if [ -x "$NETBIRD_BIN" ]; then
          break
        fi
        sleep 2
      done

      # Wait for the Homebrew-cask-installed netbird daemon to become active
      for i in {1..30}; do
        if "$NETBIRD_BIN" status >/dev/null 2>&1; then
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

      SETUP_KEY=$(cat ${config.age.secrets.netbirdSetupKey.path})

      # See darwin_apps/netbird.nix for why --disable-dns=false is required.
      #
      # --disable-ssh-auth was tried here previously to work around "SSH
      # server requires valid JWT configuration", but it's a no-op: NetBird
      # never registers a PublicKeyHandler regardless of this flag (see
      # client/ssh/server/server.go), so it doesn't add a pubkey fallback -
      # it just silences the startup error while leaving zero auth handlers
      # registered, meaning no login can ever succeed either way. The real
      # fix was server-side (management's HttpConfig.AuthAudience, see
      # modules/homelab/services/netbird/default.nix). Explicitly passing
      # --disable-ssh-auth=false (not just omitting the flag) is required
      # to actually clear it - like --disable-dns, this is a sticky
      # per-peer setting that management remembers regardless of whether
      # a later `up` call mentions it at all.
      # --ssh-jwt-cache-ttl: without it, every SSH-JWT connection (e.g. each
      # `just deploy <host>` over NetBird's embedded SSH) forces a fresh
      # interactive browser SSO login (authorize request includes
      # prompt=login unconditionally) - there's no token caching by default.
      #
      # 540s (9 min), NOT the 3600s originally tried: the SSH *server* side
      # (client/ssh/server/server.go, DefaultJWTMaxTokenAge) independently
      # enforces its own 10-minute max token age, and that ceiling is
      # currently hardcoded management-side (management/internals/shared/
      # grpc/proxy.go sends MaxTokenAgeSeconds: 0 unconditionally, meaning
      # "use the client's own 10-minute default" - there's no config/flag
      # to raise it in this NetBird version). A 3600s client-side cache
      # just meant tyr kept confidently reusing a token for up to an hour
      # that the target's SSH server would silently reject as expired
      # after 10 minutes - confirmed via the target's own
      # `journalctl -u netbird`: "JWT authentication failed: token expired
      # ... age=34m47s, max=10m0s" - with zero indication on tyr's side
      # that anything was wrong (no pkce_flow log lines at all for that
      # attempt - tyr's cache said the token was still fine, so it never
      # tried to refresh it). 540s leaves a minute of margin under the
      # 600s server ceiling.
      #
      # `netbird up` is a complete no-op whenever the daemon already reports
      # Connected - it returns right after printing "Already connected",
      # before ever reaching the code that applies flag values like this one
      # (client/cmd/up.go). The daemon auto-reconnects from its own saved
      # config on every launchd start/restart, so by the time this script's
      # `up` call runs it's usually already Connected again, and any new
      # flag here (this one included) silently never takes effect - verified
      # live: `netbird debug config` kept showing sshJWTCacheTTL: 0 no matter
      # how many times this ran or the daemon was restarted, until `down`
      # was called first. `|| true` since `down` on an already-disconnected
      # daemon (a genuinely fresh boot) isn't guaranteed to exit 0, and
      # either way `up` below is what actually needs to succeed.
      "$NETBIRD_BIN" down || true
      "$NETBIRD_BIN" up \
        --setup-key="$SETUP_KEY" \
        --management-url https://netbird.avgtechguy.com \
        --allow-server-ssh \
        --disable-ssh-auth=false \
        --disable-dns=false \
        --ssh-jwt-cache-ttl 540
    '';
    serviceConfig = {
      RunAtLoad = true;
      # Retry (rather than sitting dead until the next switch/reboot) if the
      # binary-not-installed-yet race above is ever lost anyway, or the
      # daemon isn't up in time -- but not on a successful exit, since a
      # successful `netbird up` is idempotent and re-running it forever
      # would be pointless.
      KeepAlive = {
        SuccessfulExit = false;
      };
      StandardOutPath = "/var/log/netbird-autoconfig.log";
      StandardErrorPath = "/var/log/netbird-autoconfig.err";
    };
  };
}
