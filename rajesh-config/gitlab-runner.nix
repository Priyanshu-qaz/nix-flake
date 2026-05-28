# NixOS GitLab Runner Configuration Module
#
# This module configures GitLab Runner to use Podman as the container runtime
# with a custom CA certificate for TLS verification.
#
# To use this module, add the following to your configuration.nix:
#
#   imports = [ ./nixos/gitlab-runner.nix ];
#
# Before applying, you need to create the authentication token file:
#
#   1. Copy nixos/gitlab-runner-auth-token.env.example to /etc/gitlab-runner/auth-token.env
#   2. Edit /etc/gitlab-runner/auth-token.env with your actual token values
#   3. Set proper permissions:
#      sudo chmod 600 /etc/gitlab-runner/auth-token.env
#      sudo chown root:root /etc/gitlab-runner/auth-token.env
#
# Requirements:
# - Podman must be installed and running
# - Podman socket must be available at /var/run/podman/podman.sock
# - Custom CA certificate must exist at /etc/ssl/certs/nuage-ca.crt
# - Authentication token file must exist at /etc/gitlab-runner/auth-token.env

{ config, pkgs, lib, ... }:

{
  # Enable GitLab Runner service
  services.gitlab-runner = {
    enable = true;

    # Configure runner service
    services = {
      # Main runner configuration
      runner = {
        # Authentication token configuration file
        # This file should contain CI_SERVER_URL and CI_SERVER_TOKEN environment variables
        # Use an absolute path (quoted string) to prevent it from being copied to Nix store
        authenticationTokenConfigFile = "/etc/gitlab-runner/auth-token.env";

        # Use docker executor with Podman
        executor = "docker";

        # Docker/Podman configuration
        dockerPullPolicy = "if-not-present";
        # Docker image to use by default
        dockerImage = "quay.io/podman/stable";
        # Give extended privileges to container.
        dockerPrivileged = true;
        # Docker volumes to mount
        dockerVolumes = [
          # Mount custom CA certificate into containers at multiple locations for compatibility
          # Standard location for most Linux distributions
          "/etc/ssl/certs/nuage-ca.crt:/etc/ssl/certs/nuage-ca.crt:ro"
          # Alpine/Debian/Ubuntu: mount to ca-certificates directory
          "/etc/ssl/certs/nuage-ca.crt:/usr/local/share/ca-certificates/nuage-ca.crt:ro"
          # RHEL/CentOS/Fedora: mount to ca-trust source anchors
          "/etc/ssl/certs/nuage-ca.crt:/etc/pki/ca-trust/source/anchors/nuage-ca.crt:ro"
          "/etc/ssl/certs/nuage-ca.crt:/etc/containers/certs.d/harbor.nbt.local/ca.crt:ro"
          "/etc/ssl/certs/nuage-ca.crt:/etc/docker/certs.d/harbor.nbt.local/ca.crt:ro"

          # Use Podman socket instead of Docker socket
          "/var/run/podman/podman.sock:/var/run/docker.sock"
          # Use Podman socket instead of Docker socket
          "/var/run/podman/podman.sock:/var/run/podman/podman.sock"
          # Nix Mounts
          "/nix/store:/nix/store:ro"
          "/nix/var/nix/db:/nix/var/nix/db:ro"
          "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"

        ];

        # Environment variables for the runner
        environmentVariables = {
          # Set SSL certificate file for custom CA (Python, curl, wget)
          SSL_CERT_FILE = "/etc/ssl/certs/nuage-ca.crt";
          # Alternative: set CA bundle path (Python requests)
          REQUESTS_CA_BUNDLE = "/etc/ssl/certs/nuage-ca.crt";
          # Node.js: set CA file
          NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/nuage-ca.crt";
          # Git: set CA info
          GIT_SSL_CAINFO = "/etc/ssl/certs/nuage-ca.crt";
          CI_SERVER_TLS_CA_FILE = "/etc/ssl/certs/nuage-ca.crt";
        };
        
        # Pre-build script to update CA certificates in containers
        # This runs before each job to ensure the custom CA is trusted
        preBuildScript = pkgs.writeScript "setup-container" ''
          # Update CA certificates for Alpine/Debian/Ubuntu
          if [ -f /usr/local/share/ca-certificates/nuage-ca.crt ]; then
            update-ca-certificates 2>/dev/null || true
          fi
          # Update CA trust for RHEL/CentOS/Fedora
          if [ -f /etc/pki/ca-trust/source/anchors/nuage-ca.crt ]; then
            update-ca-trust extract 2>/dev/null || true
          fi
        '';

        # Runner description
        description = "nixos-podman-runner";

        # Tags for this runner
        tagList = [ "nixos" "podman" ];


      };
    };
  };

  # Ensure Podman service is enabled and starts before GitLab Runner
  # Enable Docker compatibility mode (creates /var/run/docker.sock symlink to Podman socket)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  
  # Explicitly disable Docker to avoid conflicts
  virtualisation.docker.enable = false;

  # Systemd service dependencies
  systemd.services.gitlab-runner = {
    after = [ "podman.service" "podman.socket" ];
    requires = [ "podman.service" ];
    # Set environment variables for GitLab Runner service (which uses Podman)
    # These help ensure Podman and GitLab Runner can access the custom CA certificate
    environment = {
      # SSL certificate file for tools used by GitLab Runner
      SSL_CERT_FILE = "/etc/ssl/certs/nuage-ca.crt";
      # CA bundle for Python/requests
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/nuage-ca.crt";
      # Git SSL CA info
      GIT_SSL_CAINFO = "/etc/ssl/certs/nuage-ca.crt";
      # Node.js extra CA certs
      NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/nuage-ca.crt";
      # Podman/containers configuration directory (already configured via tmpfiles)
      # CONTAINERS_CONF is not needed as we use the default paths
    };
  };

  # Ensure required files exist and are readable
  systemd.services.gitlab-runner.preStart = ''
    if [ ! -f /etc/ssl/certs/nuage-ca.crt ]; then
      echo "Warning: Custom CA certificate not found at /etc/ssl/certs/nuage-ca.crt"
    fi
    if [ ! -S /var/run/podman/podman.sock ]; then
      echo "Warning: Podman socket not found at /var/run/podman/podman.sock"
    fi
    # Verify Podman registry certificate is in place
    if [ ! -f /etc/containers/certs.d/git.nbt.local/ca.crt ]; then
      echo "Warning: Podman registry certificate not found at /etc/containers/certs.d/git.nbt.local/ca.crt"
    fi
    if [ ! -f /etc/gitlab-runner/auth-token.env ]; then
      echo "Error: Authentication token file not found at /etc/gitlab-runner/auth-token.env"
      echo "Please create this file with CI_SERVER_URL and CI_SERVER_TOKEN environment variables"
      exit 1
    fi
  '';

  # Create symlink to CA certificate in Podman's registry-specific certificate directory
  # Podman looks for certificates in /etc/containers/certs.d/<hostname>/ca.crt
  # We'll create this via systemd tmpfiles to ensure it's a symlink to the actual certificate
  systemd.tmpfiles.rules = [
    "d /etc/gitlab-runner 0755 root root -"
    # Create Podman registry certificate directory for git.nbt.local
    "d /etc/containers/certs.d/git.nbt.local 0755 root root -"
    # Create symlink to the CA certificate
    "L+ /etc/containers/certs.d/git.nbt.local/ca.crt - - - - /etc/ssl/certs/nuage-ca.crt"
  ];
}


