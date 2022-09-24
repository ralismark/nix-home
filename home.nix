{ config, pkgs, inputs, ... }:

with config;
with pkgs;

let
  virtual2nix = name: path: pkgs.runCommand "virtual-${name}" {} ''
    mkdir -p $out/bin
    ln -s ${path} $out/bin/$name
  '';
in {
  imports = [
    ./sshfs-mounts
    ./zsh
    ./jupyter-ipython
    ./trash-collect
  ];

  home.packages = [
    nixpkgs-fmt
    (pantheon.elementary-files.overrideAttrs (final: prev: {
      mesonFlags = [ "-Dwith-zeitgeist=disabled" ];
    }))
    dfeet
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

  services.gammastep = {
    enable = false; # TODO
    tray = false;
  };

  # fortunes
  home.file.".local/fortunes".source = ./fortunes;
  home.file.".local/fortunes.dat".source = runCommand "fortunes.dat" { buildInputs = [ fortune ]; } ''
    strfile ${./fortunes} $out
  '';

  # tmux
  home.file.".tmux.conf".source = ./tmux.conf;

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
      key_bindings = let
        # vim-style key codes
        mkKey = code:
          let
            bits = lib.strings.splitString "-" code;
            key = lib.lists.last bits;
            modchars = lib.lists.init bits;
            modstrings = map (x:
              builtins.getAttr x {
                C = "Control";
                S = "Shift";
                A = "Alt";
              }) modchars;
            mods = builtins.concatStringsSep "|" modstrings;
          in (if mods == "" then { inherit key; } else { inherit key mods; });
        convert = opt@{ key, ... }: opt // mkKey key; # We override key
      in map convert [
        # clipboard things
        { key = "Copy";     action = "Copy";           }
        { key = "C-A-C";    action = "Copy";           }
        { key = "C-A-V";    action = "Paste";          }
        { key = "Paste";    action = "Paste";          }
        { key = "S-Insert"; action = "PasteSelection"; }

        # navigation
        # QUESTION 2021-10-17 why do we have ~Alt?
        { key = "S-PageUp";   mode = "~Alt"; action = "ScrollPageUp";   }
        { key = "S-PageDown"; mode = "~Alt"; action = "ScrollPageDown"; }
        { key = "S-Home";     mode = "~Alt"; action = "ScrollToTop";    }
        { key = "S-End";      mode = "~Alt"; action = "ScrollToBottom"; }

        # misc
        { key = "C-Equals"; action = "IncreaseFontSize"; }
        { key = "C-Minus";  action = "DecreaseFontSize"; }
        { key = "C-Key0";   action = "ResetFontSize";    }

        # TODO search mode
      ];
    };
  };

  programs.rofi = {
    enable = true;
    package = virtual2nix "rofi" "/usr/bin/rofi";

    theme = ./rofi-theme.rasi;

    extraConfig = {
      show-icons = true;
      sidebar-mode = false;

      modi = "combi";
      combi-modi = "drun,files:~/.local/bin/rofi-files";
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
}
