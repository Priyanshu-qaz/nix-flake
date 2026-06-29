{ config, pkgs, ... }:	
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./server.nix
      ./local-domains.nix
      ./bluetooth.nix
    ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.extraHosts = ''
  10.89.0.8 vizor.local
'';
	
  nix.nixPath = [
  "nixos-config=/etc/nixos/configuration.nix"
];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";  

# for not shutwon when i use window+l   
  services.logind.extraConfig = ''
  HandleLidSwitch=ignore
  HandleLidSwitchDocked=ignore
  IdleAction=ignore
'';


  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "in";
    variant = "eng";
  };
 
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # for agy
  programs.nix-ld.enable = true;

virtualisation.podman = {
  enable = true;
  dockerCompat = false;
  defaultNetwork.settings.dns_enabled = true;
};
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.priyanshu = {
    isNormalUser = true;
    description = "Priyanshu Singh";
    extraGroups = [ "networkmanager" "wheel" "podman" ];
    packages = with pkgs; [
    kdePackages.kate
    #  thunderbird
    ];
  };
  
  # Install firefox.
  programs.firefox.enable = true;
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    home-manager
    bash
    pkgs.podman-desktop
    kubectl  
    pkgs.teams-for-linux
    pkgs.dapr-cli
    brave
    bun
    httpie-desktop
    gemini-cli
    pkgs.dbeaver-bin
  ];

  networking.firewall.allowedTCPPorts = [ 5080 ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  
    # Add Nuage CA as Trusted CA
  security.pki.certificates = [
    ''
      -----BEGIN CERTIFICATE-----
      MIIEsjCCA5qgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBlzELMAkGA1UEBhMCSU4x
      FjAUBgNVBAgTDVV0dGFyIFByYWRlc2gxDjAMBgNVBAcTBU5vaWRhMSAwHgYDVQQK
      ExdOdWFnZSBEZXZpY2UgTWFuYWdlbWVudDErMCkGCSqGSIb3DQEJARYcZXNod2Fy
      Lm5hdGFyYWphbkBudWFnZWRtLmNvbTERMA8GA1UEAxMITnVhZ2UgQ0EwHhcNMTcw
      NjE2MDk1MjI3WhcNMjcwNjE0MDk1MjI3WjCBlzELMAkGA1UEBhMCSU4xFjAUBgNV
      BAgTDVV0dGFyIFByYWRlc2gxDjAMBgNVBAcTBU5vaWRhMSAwHgYDVQQKExdOdWFn
      ZSBEZXZpY2UgTWFuYWdlbWVudDErMCkGCSqGSIb3DQEJARYcZXNod2FyLm5hdGFy
      YWphbkBudWFnZWRtLmNvbTERMA8GA1UEAxMITnVhZ2UgQ0EwggEiMA0GCSqGSIb3
      DQEBAQUAA4IBDwAwggEKAoIBAQDOp+gO7ZiI4eNi1Wow047qVAK2n1dVqWgut7e9
      rodr8b13XbqnEmx72irqqs5g2k09JDnjHqAa3F2D9T21+Oge8FO4IG/l6j0SS4AJ
      E5b9vhQ8KJxKqpaTNEzgcq8ubs8mqZ10H/tqSjYB6JVVCBNswPkPwM7i1MwwAc4P
      UcgWmajbE4vPHVe8tDroNC/WOzdqYaZ8g7erLSve/ymGkroC3t+zL0paSFqlEAwR
      9n19SB7CdbtjDSanrMpUZ8srChIQuiaBnd4VixGulzA+0PJpdHILrlxln9gj2bJT
      f6af7J1ooSw8CvGBZ1t/tk4f0e2VVwPBUdBxwvRmOfSg7omxAgMBAAGjggEFMIIB
      ATAdBgNVHQ4EFgQUiO0QxVq3oocOc7QFJ9bKaLL+Y4owgcQGA1UdIwSBvDCBuYAU
      iO0QxVq3oocOc7QFJ9bKaLL+Y4qhgZ2kgZowgZcxCzAJBgNVBAYTAklOMRYwFAYD
      VQQIEw1VdHRhciBQcmFkZXNoMQ4wDAYDVQQHEwVOb2lkYTEgMB4GA1UEChMXTnVh
      Z2UgRGV2aWNlIE1hbmFnZW1lbnQxKzApBgkqhkiG9w0BCQEWHGVzaHdhci5uYXRh
      cmFqYW5AbnVhZ2VkbS5jb20xETAPBgNVBAMTCE51YWdlIENBggEAMAwGA1UdEwQF
      MAMBAf8wCwYDVR0PBAQDAgEGMA0GCSqGSIb3DQEBCwUAA4IBAQAYpYEwbP8T2owN
      /X1O6aJwd3AZvTKp5c9svSRDpfdwol/CLf6yAZ/aUs6QkxW05HDGFPQ+OPP21sEk
      XW7GSfqrV87+07yjkw+JNRHtO47TzAsm/9H0SjdIRduKL9biQXzDN/qV8FbYPitk
      HEzkKG+2SjXVs7EFnzXIZw6zwscyxPtOpkMgzvaViWiOwgIW3OVXn6fuzK61x3pz
      HAfXXsObvXPv5qUoMFBuOKNkxbsn2xute/ntDC8JdKOcRpeKIZQ/TBnONQBUz3E0
      78QkBEUuZNxMQv0JtRfjL0mY9OcMJWG5HRKQ6799phkmxSTvTIcr9DjYrEyDvfy8
      AN+hPqAz
      -----END CERTIFICATE-----
      	''
  ];
  # List services that you want to enable:

  # Enable the OpenSSH daemon
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
    # networking.firewall.enable = false;
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}

