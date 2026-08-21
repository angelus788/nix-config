# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A flake-parts based Nix configuration monorepo covering NixOS hosts, nix-darwin (macOS) hosts, and standalone Home Manager targets (Ubuntu, Steam Deck) for a personal homelab. Secrets are managed with agenix; per-host private data (network layout, secret files) lives in a separate flake input (`inputs.secrets`, a private Forgejo repo) rather than in this repo.

## Common commands

All common operations are wrapped in the `justfile` (uses `just`, available in the dev shell via `nix develop`).

```
just check              # nix flake check — validates all flake outputs build
just update             # nix flake update — refresh flake.lock

# NixOS hosts (remote deploy over SSH, host must be reachable by name)
just dry-run <host>     # rsync config + nixos-rebuild dry-activate on remote host
just deploy <host>      # rsync config + nixos-rebuild switch on remote host
just boot <host>        # rsync config + nixos-rebuild boot on remote host
just copy <host>        # rsync-only: sync ./ to <host>:/etc/nixos/

# NixOS local (run ON the host itself, uses `hostname -s` to pick config)
just switch             # sudo nixos-rebuild switch --flake .#$(hostname -s)
just test               # sudo nixos-rebuild test  --flake .#$(hostname -s)
just dry-switch         # nixos-rebuild dry-activate --flake .#$(hostname -s)

# nix-darwin (run locally on the Mac, uses scutil LocalHostName)
just darwin-switch
just darwin-test

# Home Manager standalone targets
just home-build <user@host>          # e.g. just home-build angelus@ubuntu
just home-switch <user@host>         # local switch, pulls flake over https from Forgejo
just home-deploy <target> [host]     # rsync + remote `home-manager switch` over SSH
just ubuntu                          # shortcut: home-deploy angelus@ubuntu ubuntu
just steamdeck                       # shortcut: home-deploy deck@steamdeck steamdeck

just build-iso <host>                # build an installer ISO for a host via nixos-generate
```

There is no host-specific test suite; correctness is validated via `nix flake check` and `nixos-rebuild dry-activate` / `darwin-rebuild build` before switching.

### Formatting/linting

Formatting is via `treefmt-nix` (configured in `modules/devshell.nix`): `nixfmt-rfc-style`, `deadnix`, and `shellcheck`. Run through the dev shell's treefmt (`nix fmt` if exposed, or `nix develop -c treefmt`).

## Architecture

### Flake output generation is directory-driven

`flake.nix` only imports three top-level generators plus the devshell:
```
./modules/machines/nixos       -> flake.nixosConfigurations
./modules/machines/darwin      -> flake.darwinConfigurations
./modules/machines/standalone  -> flake.homeConfigurations
```

Each generator (`modules/machines/{nixos,darwin,standalone}/default.nix`) works the same way: it reads its own directory (`builtins.readDir ./.`), and any subdirectory containing a `configuration.nix` (nixos/darwin) or `home.nix` (standalone) becomes a flake output named after that directory. **Adding a new host/target is done by adding a new subdirectory with the expected entry file — nothing needs to be registered elsewhere.** Per-host overrides for nixpkgs channel or system architecture are done via small lookup maps at the top of these files (`nixpkgsMap`, `systemArchMap`, `userMap`), not per-host flake wiring.

Each generator also injects shared modules into every host it builds: agenix, home-manager (with `../../users/angelus/dots.nix` + `age.nix` always imported into the user's HM config), and a `_common/default.nix` for that platform. NixOS additionally wires in `../../homelab`, `../../misc/email`, `../../misc/tg-notify`, `../../misc/mover`, disko, autoaspm, and invoiceplane on every host.

### Module layers

- `modules/machines/{nixos,darwin,standalone}/<hostname>/` — one directory per physical/logical machine. `configuration.nix` (or `home.nix`) is the host's entry point; hosts also carry host-specific `disko.nix`, `hardware-configuration.nix`, `boot.nix`, `wireguard.nix`, `secrets.nix`, etc. as needed.
- `modules/machines/{nixos,darwin}/_common/default.nix` — settings applied to every host of that platform (SSH, autoUpgrade-from-git for NixOS, base packages, overlays, agenix identity paths, etc.).
- `modules/homelab/` — defines the `homelab.*` option namespace (mounts, user/group, timeZone, baseDomain, Cloudflare DNS creds) and imports `services/`, `samba/`, `networks/`, `motd/`, `fail2ban-cloudflare/`. Only enabled on hosts that set `homelab.enable = true`.
- `modules/homelab/services/<name>/` — one NixOS module per self-hosted service (forgejo, jellyfin, immich, paperless-ngx, vaultwarden, arr stack, etc.), each defining its own `options.homelab.services.<name>` (enable, url, homepage metadata) gated by `lib.mkIf cfg.enable`. The `homepage.*` options feed the auto-generated services table in `README.md` (see below) — new services should set `homepage.name/description/icon/category` for that to work.
- `modules/apps/` — app-level modules usable across machine types (1Password, Tailscale, Netbird, desktop environments under `DE/`, etc.).
- `modules/misc/` — smaller standalone feature modules (agenix wiring, email, tg-notify, syncthing, zfs-root, tailscale, ryzen-undervolting, etc.), imported individually where needed rather than as a single bundle.
- `modules/users/angelus/` — the one human user's account definition (`default.nix`, NixOS/Darwin), dotfiles wiring (`dots.nix`), agenix secrets access (`age.nix`, `age-hm.nix`), and git config.
- `modules/dots/` — Home Manager modules for individual dotfiles/tools (nvim, zsh, tmux, ghostty, starship, etc.), imported selectively by `users/angelus/dots.nix` or per-host HM config.

### Secrets

Two separate secrets stores exist:
- `secrets/` in this repo: agenix `.age` files plus `secrets.nix` (defines which SSH public keys — per-user and per-host — can decrypt which secret) and `ssh.nix`/`networks.nix`. Edit `secrets.nix` when adding a new encrypted secret or a new host/user key.
- `inputs.secrets` (private flake input, a separate Forgejo repo, not in this checkout): provides `networks.nix` and additional `.age` files consumed via `${inputs.secrets}/...` (see `_common/default.nix` for NixOS). Its contents aren't visible locally.

Secrets are declared per-host under `age.secrets.<name>` (agenix NixOS/HM module) and referenced via `config.age.secrets.<name>.path`.

### README service table

`README.md` contains a generated block between `<!-- BEGIN SERVICE LIST -->` / `<!-- END SERVICE LIST -->`. It's produced by `bin/generateServicesTable.nix`, which introspects the built NixOS configurations for every host's `config.homelab.services.*.homepage` and `.enable`, grouped per host. This runs in CI (`.github/workflows/push.yml`) via `nix eval --offline --raw --file bin/generateServicesTable.nix`, not something to hand-edit or run ad hoc — the CI job auto-commits the regenerated README on push.

### CI

Forgejo Actions workflows in `.github/workflows/`:
- `push.yml` — regenerates the README service table on every push and commits it back.
- `update-flake-lock.yml` — nightly (`cron 0 3 * * *`) `nix flake update` + commit + push, using an Attic binary cache.

Both run on a self-hosted `nix` runner against `git.avgtechguy.com` (Forgejo), not GitHub, despite living under `.github/workflows/`.
