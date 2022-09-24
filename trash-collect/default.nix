{ config, pkgs, ... }:

with config;
with pkgs;

let
in {
  systemd.user.services.trash-collect = {
    Unit = {
      Description = "clean up old Trash";
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${./trash-collect.sh}";
    };
  };
  systemd.user.timers.trash-collect = {
    Unit = {
      Description = "clean up old Trash";
    };

    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
