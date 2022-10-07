{ config, pkgs, ... }:
with config;
let
  inherit (pkgs) lib;
  cfg = wayland.windowManager.sway;
in
{
  wayland.windowManager.sway = {
    enable = true;
    systemdIntegration = false; # we do our own custom systemd integration

    config =
      let
        # we use systemd to move the processes out of sway.service
        # TODO why double systemd-run?
        exec = "${pkgs.systemd}/bin/systemd-run --user -- ${pkgs.systemd}/bin/systemd-run --user --scope --slice=app-graphical.slice";

        per-workspace = fn:
          #  key name
          fn "1" "1" //
          fn "2" "2" //
          fn "3" "3" //
          fn "4" "4" //
          fn "5" "5" //
          fn "6" "6" //
          fn "7" "7" //
          fn "8" "8" //
          fn "9" "9" //
          fn "0" "10";
      in
      rec {
        modifier = "Mod4"; # Window key

        menu = "${exec} ${programs.rofi.package}/bin/rofi -show combi";
        terminal = "${exec} ${programs.alacritty.package}/bin/alacritty";

        bars = [ ]; # managed separately

        colors.focused = {
          border = "#22aacc";
          background = "#22aacc";
          text = "#ffffff";
          indicator = "";
          childBorder = "";
        };

        input = {
          "type:keyboard" = {
            repeat_delay = "300";
            repeat_rate = "70";
          };
          "1:1:AT_Translated_Set_2_keyboard" = {
            xkb_options = "caps:escape";
          };
          "type:mouse" = {
            left_handed = "enabled";
          };
          "type:touchpad" = {
            dwt = "disabled";
            natural_scroll = "enabled";
            pointer_accel = "0.5";
            tap = "enabled";
          };
          "type:pointer" = {
            left_handed = "disabled";
            pointer_accel = "0.5";
          };
        };

        keybindings = {
          "--locked ${modifier}+q" = ''exec "swaylock -f; systemctl suspend"'';

          # Start a terminal
          "${modifier}+Return" = "exec ${terminal}";

          # Unicode picker
          "${modifier}+u" = "exec ${exec} rofi-unicode"; # TODO don't do path search for rofi-unicode

          # Kill focused window
          "${modifier}+w" = "kill";

          # Start your launcher
          "${modifier}+Space" = "exec ${menu}";

          # dropdown terminal
          "${modifier}+Tab" =
            let
              # TODO avoid path search
              # TODO extract out name
              dropper = pkgs.writeScript "dropper" ''
                #!/bin/sh

                session_name=drop
                name=tdrop

                if [ -z "$(tmux list-clients -t "$session_name")" ]; then
                  exec ${cfg.config.terminal} --class "$name" --command tmux new-session -Ads "$session_name"
                else
                  exec tmux detach-client -s "$session_name"
                fi
              '';
            in
            "exec ${exec} ${dropper}";

          "${modifier}+n" = ''exec ${exec} ${programs.mako.package}/bin/makoctl menu ${programs.rofi.package}/bin/rofi -dmenu -p "Mako"'';

          # Special Keys -------------------------------------------------------

          # media buttons
          # TODO avoid path search
          XF86AudioRaiseVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ +10%";
          XF86AudioLowerVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ -10%";

          # do these even work
          XF86AudioPlay = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          XF86AudioNext = "exec ${pkgs.playerctl}/bin/playerctl next";
          XF86AudioPrev = "exec ${pkgs.playerctl}/bin/playerctl previous";

          XF86MonBrightnessDown = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
          XF86MonBrightnessUp = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%+";

          Print = "exec ${exec} snip"; # TODO avoid path search

          # Layout Management --------------------------------------------------

          # maybe binds that make more sense?
          "${modifier}+a" = "floating disable";
          "${modifier}+s" = "layout toggle all";
          "${modifier}+d" = "floating enable";
          "${modifier}+f" = "fullscreen toggle";

          "${modifier}+Left" = "move workspace to output left";
          "${modifier}+Right" = "move workspace to output right";

        } // per-workspace (key: ws: {
          "${modifier}+${key}" = "workspace ${ws}";
          "${modifier}+Ctrl+${key}" = "move container to workspace ${ws}";
        });

        modes = { }; # remove the default resize mode

        output = {
          "*" = {
            bg = "~/Documents/walls/WALL fill";
            adaptive_sync = "on";
          };

          "DP-1".pos = "0 0";
          "eDP-1".pos = "1920 0";
        };

        window.border = 1;
        floating.border = 1;

        startup = [
          {
            command = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE=wayland";
          }
          {
            # systemd service support
            command = "${pkgs.systemd}/bin/systemd-notify --ready";
            always = true;
          }
        ];

        # window-specific things
        window.commands = [
          {
            criteria.app_id = "dragon-drop";
            command = "sticky enable";
          }
          {
            criteria.app_id = "tdrop";
            command = "floating enable, resize set width 60ppt height 60ppt, move position center, sticky enable";
          }
        ];
      };

    extraConfig = lib.strings.concatStringsSep "\n" [
      "output '*'" # iirc this makes reloading not mess up my monitor but idk if it's still necessary
    ];
  };

  systemd.user.services.sway = {
    Unit = {
      Description = "SirCmpwn's Wayland window manager";
      Documentation = "man:sway(5)";

      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
      BindsTo = [ "graphical-session.target" ];
      Before = [ "graphical-session.target" ];
      PropagateReloadFrom = [ "graphical-session.target" ];
    };

    Service = {
      Slice = "session.slice";
      Type = "notify";
      NotifyAccess = "all"; # we use systemd-notify so we need to accept startup notifications from everyone
      ExecStart = "${cfg.package}/bin/sway";
      TimeoutStopSec = 10;

      Restart = "on-failure";
      RestartSec = 1;

      ExecReload = [
        # This errors for some reason with '[common/ipc-client.c:87] Unable to receive IPC response'
        # so we need to suppress it
        "-${cfg.package}/bin/swaymsg reload"
      ];

      # TODO also need to unset in dbus?
      ExecStopPost = "${pkgs.systemd}/bin/systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE";
    };
  };
}
