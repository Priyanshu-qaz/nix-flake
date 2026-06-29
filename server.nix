{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;

    appendHttpConfig = ''
      proxy_cache_path /var/cache/nginx/nix-cache
        levels=1:2
        keys_zone=nixcache:100m
        max_size=100g
        inactive=30d
        use_temp_path=off;
    '';

    virtualHosts."nix-cache-proxy" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8080;
        }
      ];

      locations."/" = {
        proxyPass = "https://cache.nixos.org";

        extraConfig = ''
          proxy_set_header Host cache.nixos.org;
          proxy_ssl_server_name on;

          proxy_cache nixcache;
          proxy_cache_valid 200 302 30d;
          proxy_cache_valid 404 1m;

          proxy_buffering on;
          proxy_ignore_headers Set-Cookie;
          proxy_hide_header Set-Cookie;

          add_header X-Cache-Status $upstream_cache_status always;
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
