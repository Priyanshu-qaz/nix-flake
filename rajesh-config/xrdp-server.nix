{ config, pkgs, ... }:

{

  services.xserver.enable = true;
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startplasma-x11";
#     defaultWindowManager = "${pkgs.dbus}/bin/dbus-run-session -- startplasma-x11";

    #     defaultWindowManager = "xterm";
    openFirewall = true;
  };


  environment.systemPackages = with pkgs; [
    xrdp
    dbus
    wayland-utils
    wl-clipboard
    xclip
  ];

  # Disable systemd targets for sleep and hibernation
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
