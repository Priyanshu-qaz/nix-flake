{ config, pkgs, ... }:

{
  home.file.".config/containers/registries.conf".text = ''
    # Managed by Home Manager
    # Remove ALL [registries.*] sections and use ONLY [[registry]] blocks
    # Configure Docker Hub with a mirror
    #[[registry]]
    #location = "docker.io"  # Original registry (Docker Hub)
    #insecure = false        # Use HTTPS for Docker Hub

    #prefix = ""             # Match all images under docker.io
    # Define the mirror (your local cache)
    #[[registry.mirror]]
    #location = "harbor.nbt.local"  # Pull-through cache registry
    #insecure = true # Allow HTTP for local registry


    unqualified-search-registries = ["harbor.nbt.local","docker.io"]

    [[registry]]
    prefix = "docker.io"
    location = "harbor.nbt.local/dockerhub-proxy"
    mirror-by-digest-only = false
    insecure = false

    [[registry]]
    prefix = "ghcr.io"
    location = "harbor.nbt.local/ghcr-proxy"
    mirror-by-digest-only = false
    insecure = false

    [[registry]]
    prefix = "gcr.io"
    location = "harbor.nbt.local/gcr-proxy"
    mirror-by-digest-only = false
    insecure = false

    [[registry]]
    prefix = "quay.io"
    location = "harbor.nbt.local/quay-proxy"
    mirror-by-digest-only = false
    insecure = false

    [[registry]]
    prefix = "mcr.microsoft.com"
    location = "harbor.nbt.local/mcr-proxy"
    mirror-by-digest-only = false
    insecure = false


  '';
}
