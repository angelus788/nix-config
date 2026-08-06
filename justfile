# vim: set ft=make :
set quiet

update:
  nix flake update

build-iso $host:
	just copy {{ host }}; ssh {{ host }} "nix-shell -p nixos-generators.out --run 'nixos-generate -c /etc/nixos/machines/installer/default.nix -f install-iso -I nixpkgs=channel:nixos-25.11'"

check:
  nix flake check

dry-run $host:
	nixos-rebuild dry-activate --flake .#{{host}} --target-host {{host}} --build-host {{host}} --no-reexec --sudo

deploy $host: (copy host)
	nixos-rebuild switch --flake .#{{host}} --target-host {{host}} --build-host {{host}} --no-reexec --sudo --ask-sudo-password

boot $host: (copy host)
	nixos-rebuild boot --flake .#{{host}} --target-host {{host}} --build-host {{host}} --no-reexec --sudo

check-clean:
	if [ -n "$(git status --porcelain)" ]; then echo -e "\e[31merror\e[0m: git tree is dirty. Refusing to copy configuration." >&2; exit 1; fi

copy $host:
	rsync -ax --delete --rsync-path="sudo rsync" ./ {{host}}:/etc/nixos/
	

# -----------------------------------------------------------------------------
# Standalone Home Manager targets (Ubuntu, Steam Deck, macOS, etc.)
# -----------------------------------------------------------------------------

# Apply Home Manager config locally
# Usage: just home-switch angelus@ubuntu
home-switch $target:
    nix run --refresh github:nix-community/home-manager -- switch --flake git+https://git.avgtechguy.com/avgtechguy/nix-config.git#{{target}}

# Test Home Manager build locally without activating changes
# Usage: just home-build deck@steamdeck
home-build $target:
    nix build --refresh .#homeConfigurations."{{target}}".activationPackage

# Remote deploy Home Manager via SSH to a standalone target
# Usage: just home-deploy deck@steamdeck
home-deploy $target:
    ssh {{ target }} "nix run --refresh github:nix-community/home-manager -- switch