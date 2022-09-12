{ config, pkgs, ... }:

with config;
with pkgs;

let
  mounts = {
    "dev2" = "dev2:";
    "dev4" = "dev4:";
    "dev1c" = "dev1c:";
    "relay" = "relay:";
    "cse" = "cse:";
  };

  mountBase = "${home.homeDirectory}/.local/mount/";

  # -----------------------------------------------------------------------------

  # Escape a path according to the systemd rules, e.g. /dev/xyzzy
  # becomes dev-xyzzy.
  # from <nixpkgs/nixos/lib/utils.nix>
  escapeSystemdPath = s:
    lib.replaceChars [ "/" "-" " " ] [ "-" "\\x2d" "\\x20" ]
    (lib.removePrefix "/" s);
in {
  programs.zsh.dirHashes = lib.attrsets.mapAttrs' (mountName: target: {
    name = mountName;
    value = "${mountBase}${mountName}";
  }) mounts;

  systemd.user.mounts = let
    makeMount = mountName: target:
      let mountpoint = "${mountBase}${mountName}";
      in {
        name = escapeSystemdPath mountpoint;
        value = {
          Unit = {
            Description = "sshfs mount ${target} to ${mountpoint}";
          };

          Mount = {
            What = target;
            Where = mountpoint;
            Type = "fuse.sshfs";
            Options = builtins.concatStringsSep "," [
              "idmap=user"
              "x-systemd.automount"
              "_netdev"
              # sshfs opts
              "reconnect"
              #"delay_connect"
              # ssh opts
              "ControlPath=none"
              "ServerAliveInterval=15"
            ];
            LazyUnmount = true;
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };
  in lib.attrsets.mapAttrs' makeMount mounts;
}
