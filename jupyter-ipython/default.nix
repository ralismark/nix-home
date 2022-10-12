{ config, pkgs, ... }:

with config;
with pkgs;

let
in {
  home.packages = [
    # TODO
  ];

  # ipython
  home.file.".ipython/profile_default/startup" = {
    source = ./startup;
  };

  home.file.".ipython/profile_default/ipython_config.py" = {
    # TODO where to find docs for this
    text = ''
      ## A list of dotted module names of IPython extensions to load.
      c.InteractiveShellApp.extensions = ["autoreload"]
    '';
  };

  # jupyter
  systemd.user.services.jupyter = {
    Unit.Description = "Jupyter Notebook";

    Service = {
      Type = "simple";
      ExecStart = builtins.concatStringsSep " " [
        "/usr/bin/jupyter" # TODO nixify path
        "notebook"
        "--MappingKernelManager.cull_idle_timeout=3600"
        "--NotebookApp.open_browser=False"
        "--NotebookApp.port=8889"
        "--NotebookApp.token="
      ];
      WorkingDirectory = "%h";
      Restart = "always";
      RestartSec = 10;
      Nice = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
