{ config, pkgs, ... }:
with config;
{
  # TODO swaylock doesn't work in genericLinux environment
  # home.packages = [ pkgs.swaylock ];

  programs.swaylock.settings = {
    color = "252525";
    font = "Droid Sans Mono";
    font-size = 35;

    line-uses-ring = true;
    ignore-empty-password = true;

    indicator = true;
    clock = true;
    datestr = "%a, %-e %b %Y";

    indicator-radius = 100;
    indicator-thickness = 10;

    ring-color = "00000000";
    ring-ver-color = "00000022";
    ring-clear-color = "fd971f";
    ring-wrong-color = "ef6769";
    key-hl-color = "a6e22e";
    bs-hl-color = "fd971f";

    inside-color = "00000000";
    inside-clear-color = "00000000";
    inside-ver-color = "00000000";
    inside-wrong-color = "00000000";

    separator-color = "00000000";

    text-color = "ffffff";
    text-clear-color = "ffffff";
    text-caps-lock-color = "ffffff";
    text-ver-color = "ffffff";
    text-wrong-color = "ffffff";

    image = "~/Documents/walls/WALL";
    effect-scale = "0.05";
    effect-blur = "3x3";
    effect-vignette = ".3:.3";
  };
}
