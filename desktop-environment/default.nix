{ config, pkgs, ... }:
with config;
{
  imports = [
    ./sway.nix
    ./mako.nix
    ./gammastep.nix
    ./waybar.nix
    ./swaylock.nix
  ];

  # bootstrap into environment
  programs.zsh.profileExtra = ''
    if ${pkgs.systemd}/bin/systemctl -q is-active graphical.target &&
      ! ${pkgs.systemd}/bin/systemctl -q --user is-active sway.service &&
      [[ $XDG_VTNR -eq 1 ]]; then

      # Import vars needed to start sway
      ${pkgs.systemd}/bin/systemctl --user import-environment XDG_SEAT XDG_SESSION_CLASS XDG_SESSION_ID XDG_SESSION_TYPE XDG_VTNR
      exec ${pkgs.systemd}/bin/systemctl --user start --wait sway
    fi
  '';

}
