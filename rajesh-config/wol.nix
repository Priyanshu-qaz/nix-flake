{ config, pkgs, ... }:

{
  # Enable Wake-on-LAN for your network interface
  networking.interfaces.enp2s0.wakeOnLan.enable = true;
}
