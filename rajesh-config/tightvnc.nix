{ config, pkgs, lib, ... }:

let
  cfg = config.services.tigervnc;
in
{
  options.services.tigervnc = {
    enable = lib.mkEnableOption "TigerVNC x0vncserver (mirrors :0)";
    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
        options = {
          enableSharing = lib.mkOption { type = lib.types.bool; default = true; };
          port = lib.mkOption { type = lib.types.int; default = 5901; };
          localhost = lib.mkOption { type = lib.types.bool; default = false; };
          #geometry = lib.mkOption { type = lib.types.str; default = ""; };
        };
      }));
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tigervnc pkgs.xorg.xhost pkgs.xorg.xauth ];

    systemd.user.services = lib.mapAttrs' (user: opts:
      let svcName = "tigervnc-x0vncserver-${user}";
      in {
        name = svcName;
        value = lib.mkIf opts.enableSharing {
          description = "TigerVNC x0vncserver sharing :0 for ${user}";
          after = [ "graphical-session.target" "display-manager.service"];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];

          path = [ pkgs.tigervnc pkgs.xorg.xhost pkgs.xorg.xauth pkgs.coreutils ];

          script = let
            # Build args array to avoid shell escaping hell
            vncArgs = [
              "-display :0"
              "-rfbport ${toString opts.port}"
              "-rfbauth $HOME/.vnc/passwd"
              "-AcceptSetDesktopSize=0"
              "-AlwaysShared"
            ] #++ lib.optionals (opts.geometry != "") [ "-Geometry ${opts.geometry}" ]
              ++ lib.optionals opts.localhost [ "-localhost" ];
          in ''
            set -euxo pipefail

            # Password check
            mkdir -p "$HOME/.vnc"
            if [ ! -r "$HOME/.vnc/passwd" ]; then
              echo "ERROR: Run: vncpasswd ~/.vnc/passwd" >&2
              exit 1
            fi

            # X authority
            # xhost +local:
            xhost +SI:localuser:${user}


            # Clean x0vncserver args
            ${pkgs.tigervnc}/bin/x0vncserver ${lib.concatStringsSep " " (map (arg: "${arg}") vncArgs)}
          '';

          preStop = ''
            xhost -local:
            pkill -f "x0vncserver.*${toString opts.port}"
          '';

          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = "5s";
            RuntimeDirectory = "vnc-${user}";
            Environment = [
                "DISPLAY=:0"
                "XAUTHORITY=%h/.Xauthority"
            ];
          };
        };
      }
    ) cfg.users;

    networking.firewall.allowedTCPPorts =
      lib.mapAttrsToList (_: opts: opts.port) cfg.users;
  };
}
