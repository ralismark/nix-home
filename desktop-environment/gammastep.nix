{ config, pkgs, ... }:
with config;

{
  services.gammastep = {
    enable = true;
    provider = "geoclue2";
    tray = false;
  };
}
