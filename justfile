# vim: set ft=make :
set quiet

# -----------------------------------------------------------------------------
# Maintenance & Utility Recipes
# -----------------------------------------------------------------------------

update:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Updating flake lockfile..."
    nix flake update

check:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Checking flake outputs for errors..."
    nix flake check

check-clean:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "\e[31merror\e[0m: Git working tree is dirty. Refusing to deploy configuration." >&2
        exit 1
    fi

build-iso host:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Building installer ISO for host '{{host}}'..."
    just copy {{host}}
    ssh {{host}} "nix-shell -p nixos-generators.out --run 'nixos-generate -c /etc/nixos/machines/installer/default.nix -f install-iso -I nixpkgs=channel:nixos-25.11'"

copy host:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Copying configuration sources to '{{host}}':/etc/nixos/..."
    rsync -ax --delete --rsync-path="sudo rsync" ./ {{host}}:/etc/nixos/

# -----------------------------------------------------------------------------
# NixOS System Deployments
# -----------------------------------------------------------------------------

dry-run host:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Dry-running NixOS system activation on host '{{host}}'..."
    nixos-rebuild dry-activate --flake .#{{host}} --target-host {{host}} --build-host {{host}} --no-reexec --sudo

deploy host: (copy host)
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Deploying NixOS system configuration to host '{{host}}'..."
    nixos-rebuild switch --flake .#{{host}} --target-host {{host}} --build-host {{host}} --no-reexec --sudo --ask-sudo-password

boot host: (copy host)
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Staging NixOS boot configuration on host '{{host}}'..."
    nixos-rebuild boot --flake .#{{host}} --target-host {{host}} --build-host {{host}} --no-reexec --sudo

# -----------------------------------------------------------------------------
# nix-darwin System Deployments (macOS)
# -----------------------------------------------------------------------------

# Local activation for macOS
darwin-switch target="default":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Applying nix-darwin system configuration locally..."
    darwin-rebuild switch --flake .#{{target}}

# Remote activation over SSH for macOS
darwin-deploy target host=target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Deploying nix-darwin system configuration '{{target}}' to macOS host '{{host}}'..."
    ssh -A "{{host}}" "darwin-rebuild switch --flake .#{{target}}"

# -----------------------------------------------------------------------------
# Standalone Home Manager Targets (Ubuntu, Steam Deck, macOS user profile, etc.)
# -----------------------------------------------------------------------------

# Apply Home Manager config locally
# Usage: just home-switch angelus@ubuntu
home-switch target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Applying Home Manager configuration '{{target}}' locally..."
    nix run --refresh github:nix-community/home-manager -- switch --flake "git+https://git.avgtechguy.com/avgtechguy/nix-config.git#{{target}}"

# Test Home Manager build locally without activating changes
# Usage: just home-build deck@steamdeck
home-build target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Building Home Manager activation package for '{{target}}'..."
    nix build --refresh .#homeConfigurations."{{target}}".activationPackage

# Remote deploy Home Manager via SSH to a standalone target
# Usage: just home-deploy deck@steamdeck steamdeck
home-deploy target host=target:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Deploying Home Manager configuration '{{target}}' to host '{{host}}'..."
    ssh -A "{{host}}" "nix run --refresh github:nix-community/home-manager -- switch --flake 'git+https://git.avgtechguy.com/avgtechguy/nix-config.git#{{target}}'"

# -----------------------------------------------------------------------------
# Host Shortcuts
# -----------------------------------------------------------------------------

ubuntu:
    just home-deploy angelus@ubuntu ubuntu

steamdeck:
    just home-deploy deck@steamdeck steamdeck