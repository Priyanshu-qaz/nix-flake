{ config, pkgs, ... }:

{
  home.username = "priyanshu";
  home.homeDirectory = "/home/priyanshu";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    git
    firefox
    htop
    curl
    wget
    pkgs.vscode
    kind
    kubectl
    pkgs.trivy
    k9s
  ];

  programs.git = {
    enable = true;
    userName = "Priyanshu Singh";
    userEmail = "priyanshusingh271180@gmail.com";
  };

  programs.bash.enable = true;
}
