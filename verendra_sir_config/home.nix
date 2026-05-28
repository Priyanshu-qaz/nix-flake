{ config, pkgs, ... }:

{

  imports = [
    ./registries.nix
  ];
  home.username = "verendra";
  home.homeDirectory = "/home/verendra";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    git
    vim
    neovim
    google-chrome
    htop
    curl
    wget
    kubernetes-helm
    k9s
    vscode
    nodejs_24
    bun
    mssql_jdbc
  ];

  programs.git = {
    enable = true;

    settings.user.name = "verendra.kumar@nuagebiz.tech";
    settings.user.email = "verendra.kumar@nuagebiz.tech";
  };

  programs.bash.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };



}
