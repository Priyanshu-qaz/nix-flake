# nix-flake
Reproducible environment in nixos via home.nix and flake.nix

add inside sudo nano/etc/nixos/configuration.nix 
nix.settings.experimental-features = [ "nix-command" "flakes" ];
and  in users.user.pkgs - home-manager
rebuild - sudo nixos-rebuild switch

create a dir
mkdir -p ~/.config/home-manager
cd ~/.config/home-manager

add home.nix and flake.nix



