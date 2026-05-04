{ config, pkgs, ... }:

{
  home.username = "mohit";
  home.homeDirectory = "/home/mohit";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [

    # Browser
    google-chrome

    # Editors
    vscode
    sublime4
    cursor

    # API Tool
    postman

    # Diff Tool
    meld

    # Database
    pgadmin4
  ];
}
