{ config, pkgs, ... }:
with config;
{
  imports = [
    ./sway.nix
    ./mako.nix
    ./gammastep.nix
    ./waybar.nix
  ];
}
