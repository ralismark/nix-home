{ config, pkgs, inputs, lib, ... }:

# TODO make <nixpkgs> everywhere refer to a specific version, with possible overrides and stuff.
# - adjust NIX_PATH to have the same nixpkgs
# - nix flake registry with it

# TODO git

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
      links = {
        vim = "${home.homeDirectory}/src/github.com/ralismark/vimfiles/result/bin/vim";
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

  home.packages = [
    pkgs.nixpkgs-fmt
    (pkgs.pantheon.elementary-files.overrideAttrs (final: prev: {
      mesonFlags = [ "-Dwith-zeitgeist=disabled" ];
    }))
    pkgs.dfeet
    pathlinks
    pkgs.nomacs
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/src/github.com/ralismark/micro"
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Automatically set some environment variables that will ease usage of
  # software installed with nix on non-NixOS linux
  targets.genericLinux.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "timmy";
  home.homeDirectory = "/home/${home.username}";

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
    font.size = 13;

    iconTheme.name = "Numix-Reborn";
    theme.name = "Adapta-Nokto-Eta-Maia";

    gtk3.bookmarks =
      [ "file:///home/timmy/projects/pcon pcon" "file:///tmp tmp" "file:///scratch scratch" ];
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
  };
  systemd.user.sessionVariables = home.sessionVariables // {
    PATH = "$PATH\${PATH:+:}${lib.concatStringsSep ":" home.sessionPath}";
  };

  # fortunes
  home.file.".local/fortunes".source = ./fortunes;
  home.file.".local/fortunes.dat".source = pkgs.runCommand "fortunes.dat" {} ''
    ${pkgs.fortune}/bin/strfile ${./fortunes} $out
  '';

  # tmux
  home.file.".tmux.conf".source = ./tmux.conf;

  home.file.".cache/nix-index/files".source = inputs.nix-index-database.legacyPackages.${nixpkgs.system}.database;
  programs.nix-index = {
    enable = true;
  };

  systemd.user.slices.background-gopls = {
    Unit.Description = "Go Language Server";

    Slice = {
      # Make sure it can't take up too much of main memory
      MemoryHigh = "30%";
      MemoryMax = "40%";
      MemorySwapMax = "infinity";
    };
  };

  programs.alacritty = {
    # see https://github.com/alacritty/alacritty/blob/master/alacritty.yml
    # last updated: 2021-10-17, for v0.9.0
    # (hotfixed window.opacity 2022-02-06)
    enable = true;
    package = virtual2nix "alacritty" "/usr/bin/alacritty";

    settings = {
      env.TERM = "xterm-256color";

      import = [
        "~/.cache/wal/colors-alacritty.yml" # colorscheme
      ];

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
      key_bindings =
        let
          # vim-style key codes
          mkKey = code:
            let
              bits = lib.strings.splitString "-" code;
              key = lib.lists.last bits;
              modchars = lib.lists.init bits;
              modstrings = map
                (x:
                  builtins.getAttr x {
                    C = "Control";
                    S = "Shift";
                    A = "Alt";
                  })
                modchars;
              mods = builtins.concatStringsSep "|" modstrings;
            in
            (if mods == "" then { inherit key; } else { inherit key mods; });
          convert = opt@{ key, ... }: opt // mkKey key; # We override key
        in
        map convert [
          # clipboard things
          { key = "Copy"; action = "Copy"; }
          { key = "C-A-C"; action = "Copy"; }
          { key = "C-A-V"; action = "Paste"; }
          { key = "Paste"; action = "Paste"; }
          { key = "S-Insert"; action = "PasteSelection"; }

          # navigation
          # QUESTION 2021-10-17 why do we have ~Alt?
          { key = "S-PageUp"; mode = "~Alt"; action = "ScrollPageUp"; }
          { key = "S-PageDown"; mode = "~Alt"; action = "ScrollPageDown"; }
          { key = "S-Home"; mode = "~Alt"; action = "ScrollToTop"; }
          { key = "S-End"; mode = "~Alt"; action = "ScrollToBottom"; }

          # misc
          { key = "C-Equals"; action = "IncreaseFontSize"; }
          { key = "C-Minus"; action = "DecreaseFontSize"; }
          { key = "C-Key0"; action = "ResetFontSize"; }

          # TODO search mode
        ];
    };
  };

  programs.rofi =
    let
      rofi-files = pkgs.writeScript "rofi-files" ''
        #!${pkgs.bash}/bin/bash

        get_entries() {
          cd "$HOME" || exit
          find -L /tmp -maxdepth 1 -print
          find -L . ./Downloads ./work -maxdepth 2 -print
          find -L ./Documents -print
          find -L ./projects -path ./projects/pacman -prune -o -name ".?*" -prune -o -name "build" -prune -o -print
          # find -L . -name ".?*" -prune -o -name "build" -prune -o -path ~/Android -prune -o -print
        }

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
          coproc get-entries > "$SAVE"
        fi
      '';
    in
    {
      enable = true;
      package = virtual2nix "rofi" "/usr/bin/rofi";

      theme = ./rofi-theme.rasi;

      extraConfig = {
        show-icons = true;
        sidebar-mode = false;

        modi = "combi";
        combi-modi = "drun,files:${rofi-files}";
        combi-hide-mode-prefix = true;
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



}
