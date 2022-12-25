{ config, pkgs, inputs, lib, ... }:

# TODO make <nixpkgs> everywhere refer to a specific version, with possible overrides and stuff.
# - adjust NIX_PATH to have the same nixpkgs
# - nix flake registry with it

with config;
let
  virtual2nix = name: path: pkgs.runCommand "virtual-${name}" { } ''
    mkdir -p $out/bin
    ln -s ${path} $out/bin/${name}
  '';

  lock = builtins.fromJSON (builtins.readFile ./flake.lock);

  lock-inputs =
    assert lib.asserts.assertMsg (lock.version == 7) "flake.lock version has changed!";
    builtins.mapAttrs
      (_: n: lock.nodes.${n})
      lock.nodes.${lock.root}.inputs;


  pathlinks =
    let
      tunnel-run = "${home.homeDirectory}/src/github.com/ralismark/micro/tunnel-run";
      links = {
        vim = "${home.homeDirectory}/src/github.com/ralismark/vimfiles/result/bin/vim";
        # git = tunnel-run; # TODO
        make = tunnel-run;
      };
    in
    pkgs.runCommandLocal "symlinks" { } ''
      mkdir -p $out/bin
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: path: "ln -s ${path} $out/bin/${name}") links)}
    '';
in
{
  imports = [
    ./desktop-environment
    ./sshfs-mounts
    ./zsh
    ./jupyter-ipython
    ./trash-collect
  ];

  # home.sessionPath2 = lib.mkBefore [
  #   "bar"
  #   "baz"
  # ];

  home.packages = [
    pathlinks
  ] ++ (with pkgs; [
    nixpkgs-fmt
    pantheon.elementary-files
    dfeet
    nomacs
  ]);

  home.sessionPath = [
    "$HOME/src/github.com/ralismark/micro"
  ];
  # HACK until we have better sessionPath handling
  home.sessionVariablesExtra = ''
    export PATH="$HOME/.local/bin''${PATH:+:}$PATH"
  '';


  #
  # General Environment Config
  #

  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixUnstable;
  nix.registry.nixpkgs = {
    # pin the system nixpkgs to what we use
    from = {
      id = "nixpkgs";
      type = "indirect";
    };
    to = lock-inputs.nixpkgs.locked;
  };
  nix.registry.nixos-unstable = {
    from = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
    to = lock-inputs.nixpkgs.locked;
  };

  fonts.fontconfig.enable = true;

  gtk = {
    enable = true;

    font.name = "Droid Sans Regular";
    font.package = pkgs.droid-fonts;
    font.size = 13;

    iconTheme = {
      package = pkgs.numix-reborn-icon-themes;
      name = "Numix-Reborn";
    };
    theme = {
      package = pkgs.adapta-maia-theme;
      name = "Adapta-Nokto-Eta-Maia";
    };

    gtk3.bookmarks =
      [ "file://${home.homeDirectory}/projects/pcon pcon" "file:///tmp tmp" "file:///scratch scratch" ];
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  # import all session vars into systemd
  home.sessionVariables = {
    EDITOR = "vim"; # TODO no path search
    VISUAL = "vim";
    MANPAGER = "vim +Man!";
    BROWSER = "firefox";
    NIX_PATH = lib.concatStringsSep ":" [
      "nixpkgs=${inputs.nixpkgs}"
    ];
  };
  systemd.user.sessionVariables =
    (builtins.removeAttrs home.sessionVariables ["NIX_PATH"])
    // {
      PATH = "$HOME/.local/bin:$PATH\${PATH:+:}${lib.concatStringsSep ":" home.sessionPath}";
    };
  # `targets.genericLinux.enable = true` set `systemd.user.sessionVariables.NIX_PATH`, so we need to override it another way
  xdg.configFile."environment.d/11-home-manager-overrides.conf".text = ''
    NIX_PATH=${builtins.toString home.sessionVariables.NIX_PATH}
  '';

  # Misc ---------------------------------------------------------------------

  systemd.user.slices.background-gopls = {
    Unit.Description = "Go Language Server";

    Slice = {
      # Make sure it can't take up too much of main memory
      MemoryHigh = "20%";
      MemoryMax = "30%";
      MemorySwapMax = "infinity";
    };
  };

  # fortunes
  home.file.".local/fortunes".source = ./fortunes;
  home.file.".local/fortunes.dat".source = pkgs.runCommand "fortunes.dat" {} ''
    ${pkgs.fortune}/bin/strfile ${./fortunes} $out
  '';

  # Programs -----------------------------------------------------------------

  # tmux
  home.file.".tmux.conf".source = ./tmux.conf;

  # nix-index
  home.file.".cache/nix-index/files".source = inputs.nix-index-database.legacyPackages.${nixpkgs.system}.database;
  programs.nix-index = {
    enable = true;
  };

  # git
  programs.git = let
    idents = [
      {
        alias = "ac";
        origin = "git@gitlab.com:autumn-compass*/**";
        name = "Temmie Yao";
        email = "temmie@autumncompass.com";
      }
      {
        alias = "cse";
        origin = "gitlab@gitlab.cse.unsw.edu.au:*/**";
        name = "Temmie Yao";
        email = "t.yao@unsw.edu.au";
      }
      {
        alias = "github";
        origin = "git@github.com:*/**";
        name = "ralismark";
        email = "13449732+ralismark@users.noreply.github.com";
      }
    ];
  in {
    enable = true;

    aliases = {
      default-branch = "symbolic-ref --short HEAD";
      shallow-clone = "clone --recursive --depth 1";
      dl = "clone --recursive";
      co = "checkout";
      ap = "add -p";
      unap = "reset -p";

      # TODO foresta
      hist = "foresta --style=10 --svdepth=10 --graph-symbol-commit=● --graph-symbol-merge=▲ --graph-symbol-tip=∇  --date-order --reverse --no-status --boundary";
      graph = "hist --all -n20";
      grapha = "hist --all";

      loggraph = "log --graph --format=format:'\t%C(yellow)%h%C(reset) - %C(green)(%ar)%C(reset) %s  %C(auto)%d%C(reset)' --all --date-order";
      graph2 = "log --graph --format=format:'%C(yellow)%h%C(reset) - %C(blue)%aD%C(reset) %C(green)(%ar)%C(reset)%C(auto)%d%C(reset)%n          %C(white)%s%C(reset) %C(bold black)- %an%C(reset)' --all --date-order";

      amend = "commit --amend --no-edit";
      follow = "log -p --follow --";
      shove = "push --force-with-lease";
      clear = "reset HEAD";
      info = "status -sb";
      bleach = "!git reset --hard HEAD && git clean -xdff";

      fu = "merge --ff-only @{u}";

      standup = ''!git log --author="$(git config user.name)" --all --date-order --relative-date --format='%Cgreen%h %Cblue%ad %Creset%s%Cred%d%Creset' --since=yesterday'';

      wdiff = "diff -w --color-words";
      sdiff = "diff --cached";
      bdiff = "!git diff $(git merge-base HEAD $(git default-branch))..HEAD";
    } // lib.listToAttrs (map ({ alias, origin, name, email }: {
      name = "id-${alias}";
      value = ''!git config --local user.name "${name}" && git config --local user.email "${email}"'';
    }) idents);

    extraConfig = {
      core = {
        autoclrf = "input";
        eol = "lf";
        hideDotFiles = false;
        symlinks = true;
      };

      advice.detachedHead = false;
      credential.helper = "cache";

      diff.algorithm = "patience";
      diff.context = 10;
      diff.wordRegex = "[^[:punct:][:space:]]+|[[:punct:][:space:]]";

      fetch.prune = true;
      fetch.pruneTags = true;

      grep.lineNumber = true;

      init.defaultBranch = "main";

      interactive.singleKey = true;

      pull.rebase = true;

      push.default = "simple";
      push.autoSetupRemote = true;

      rebase.autoSquash = true;
      rebase.autoStash = true;

      user.useConfigOnly = true;

      # replace urls e.g. for go
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";
      # but not for crates.io
      url."https://github.com/rust-lang/crates.io-index".insteadOf = "https://github.com/rust-lang/crates.io-index";
    };

    includes =
      (map ({ alias, origin, name, email }: {
        condition = "hasconfig:remote.*.url:${origin}";
        contents.user = { inherit name email; };
      }) idents);
  };

  programs.alacritty = {
    # see https://github.com/alacritty/alacritty/blob/master/alacritty.yml
    # last updated: 2021-10-17, for v0.9.0
    # (hotfixed window.opacity 2022-02-06)
    enable = true;
    package = virtual2nix "alacritty" "/usr/bin/alacritty";

    settings = {
      env.TERM = "xterm-256color";

      colors = {
        primary.background = "#010016";
        primary.foreground = "#ffffff";

        normal.black = "#252525";
        normal.red = "#ef6769";
        normal.green = "#a6e22e";
        normal.yellow = "#fd971f";
        normal.blue = "#6495ed";
        normal.magenta = "#deb887";
        normal.cyan = "#b0c4de";
        normal.white = "#dbdcdc";
      };

      window.padding = {
        x = 2;
        y = 2;
      };
      window.decorations = "none";
      window.opacity = 0.75;

      font = {
        normal.family = "Cascadia Code PL";
        size = 13.0;
        offset = {
          x = 0;
          y = 1;
        };
      };
      draw_bold_text_with_bright_colors = true;

      selection.save_to_clipboard = false; # Explicitly require copy command

      cursor.shape = "Block";

      # List with all available hints
      #
      # Each hint must have a `regex` and either an `action` or a `command` field.
      # The fields `mouse`, `binding` and `post_processing` are optional.
      #
      # The fields `command`, `binding.key`, `binding.mods`, `binding.mode` and
      # `mouse.mods` accept the same values as they do in the `key_bindings` section.
      #
      # The `mouse.enabled` field controls if the hint should be underlined while
      # the mouse with all `mouse.mods` keys held or the vi mode cursor is above it.
      #
      # If the `post_processing` field is set to `true`, heuristics will be used to
      # shorten the match if there are characters likely not to be part of the hint
      # (e.g. a trailing `.`). This is most useful for URIs.
      #
      # Values for `action`:
      #   - Copy
      #       Copy the hint's text to the clipboard.
      #   - Paste
      #       Paste the hint's text to the terminal or search.
      #   - Select
      #       Select the hint's text.
      #   - MoveViModeCursor
      #       Move the vi mode cursor to the beginning of the hint.
      hints.enabled = [
        {
          regex = ''
            (ipfs:|ipns:|magnet:|mailto:|gemini:|gopher:|https:|http:|news:|file:|git:|ssh:|ftp:)[^<>"\\s{-}\\^⟨⟩`]+'';
          command = "xdg-open";
          post_processing = true;
          mouse.enabled = true;
          #mouse.mods = "Control";
          mouse.mods = "None";
        }
        {
          regex = ''[A-Za-z0-9_.-]*(/[A-Za-z0-9_.-]+){3,}'';
          command = "wl-copy";
          post_processing = true;
          mouse.enabled = true;
          #mouse.mods = "Shift";
          mouse.mods = "None";
        }
        {
          regex = ''(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])\\.(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])\\.(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])\\.(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])'';
          command = "wl-copy";
          mouse.enabled = true;
          mouse.mods = "None";
        }
      ];

      # NOTE: We don't use or support vim mode
      key_bindings = [
          # clipboard things
          { key = "Copy"; action = "Copy"; }
          { mods = "Control|Alt"; key = "C"; action = "Copy"; }
          { mods = "Control|Alt"; key = "V"; action = "Paste"; }
          { key = "Paste"; action = "Paste"; }
          { mods = "Shift"; key = "Insert"; action = "PasteSelection"; }

          # navigation
          # QUESTION 2021-10-17 why do we have ~Alt?
          { mods = "Shift"; key = "PageUp"; mode = "~Alt"; action = "ScrollPageUp"; }
          { mods = "Shift"; key = "PageDown"; mode = "~Alt"; action = "ScrollPageDown"; }
          { mods = "Shift"; key = "Home"; mode = "~Alt"; action = "ScrollToTop"; }
          { mods = "Shift"; key = "End"; mode = "~Alt"; action = "ScrollToBottom"; }

          # font sizing
          { mods = "Control"; key = "Equals"; action = "IncreaseFontSize"; }
          { mods = "Control"; key = "Minus"; action = "DecreaseFontSize"; }
          { mods = "Control"; key = "Key0"; action = "ResetFontSize"; }

          # TODO search mode
        ];
    };
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;

    theme = ./rofi-theme.rasi;

    extraConfig = {
      show-icons = true;
      sidebar-mode = false;

      modi = "combi";
      combi-hide-mode-prefix = true;
      combi-modi = let
        get-entries = pkgs.writeScript "get-entries" ''
          #!${pkgs.bash}/bin/bash
          get_entries() {
            cd "$HOME" || exit
            find -L /tmp -maxdepth 1 -print
            find -L . ./Downloads ./work -maxdepth 2 -print
            find -L ./Documents -print
            find -L ./projects -path ./projects/pacman -prune -o -name ".?*" -prune -o -name "build" -prune -o -print
            # find -L . -name ".?*" -prune -o -name "build" -prune -o -path ~/Android -prune -o -print
          }
          get_entries > "$1"
        '';
        rofi-files = pkgs.writeScript "rofi-files" ''
          #!${pkgs.bash}/bin/bash

          if [ -n "$*" ]; then
            # We're given a prompt
            coproc xdg-open "$*" >/dev/null 2>&1
          else
            # Startup - populate entries
            SAVE="$HOME/.cache/rofi-files"
            if [ -f "$SAVE" ]; then
              cat "$SAVE"
            else
              echo ""
            fi
            coproc ${get-entries} "$SAVE"
          fi
        '';
      in "drun,files:${rofi-files}";
    };
  };

  # programs.htop = {
  #   enable = false; # htop attempts to write to config file
  #
  #   settings = with config.lib.htop; let
  #     l_meters = leftMeters [ (bar "LeftCPUs") (bar "Memory") (bar "Swap") ];
  #     r_meters = rightMeters [ (bar "RightCPUs") (text "Uptime") (text "Systemd") ];
  #   in {
  #     cpu_count_from_one = 1;
  #     delay = 15;
  #     highlight_base_name = 1;
  #     highlight_megabytes = 1;
  #
  #     hide_userland_threads = 1;
  #
  #     fields = with fields; [ PID NICE USER IO_RATE PERCENT_CPU PERCENT_MEM M_PSS M_PSSWP STATE TIME COMM ];
  #   } // l_meters // r_meters;
  # };

  # Clone Organisation ------------------------------------

  home.activation.clones =
    let
      root = "${home.homeDirectory}/src";
      clones = {
        "${root}/github.com/ralismark/micro" = "git@github.com:ralismark/micro.git";
        "${root}/github.com/ralismark/nix-home" = "git@github.com:ralismark/nix-home.git";
        "${root}/github.com/ralismark/vimfiles" = "git@github.com:ralismark/vimfiles.git";
      };
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList
          (path: remote:
            ''
              if ! [ -e ${path} ]; then
                mkdir -p ${path}
                ${pkgs.git}/bin/git clone --recursive ${remote} ${path}
              fi
            ''
          )
          clones
      )
    );


  # Home Manager --------------------------------------------------------------

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";

  home.homeDirectory = "/home/${home.username}";

}
