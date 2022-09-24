{ config, pkgs, inputs, ... }:

with config;
with pkgs;

let
in {
  programs.direnv = {
    enable = true;

    nix-direnv.enable = true;
  };

  programs.zsh = rec {
    enable = true;

    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;

    defaultKeymap = "emacs";

    history = {
      path = "$HOME/.histfile"; # TODO 2021-11-14 move this out of home directory
      extended = true;
      ignoreDups = true;
      share = true;
      save = 100000; # 100_000
      size = 100000;
    };

    initExtra = ''
      source "/usr/share/doc/pkgfile/command-not-found.zsh"

      ##
      ## completion options
      ##

      zstyle ':completion:*' completer _complete _ignored
      zstyle ':completion:*' list-colors ""
      zstyle ':completion:*' matcher-list "m:{[:lower:]}={[:upper:]}"
      zstyle ':completion:*' menu select
      zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
      zstyle ':completion:*' rehash true
      zstyle ':completion:*:warnings' format "%B$fg[red]%}--- no match for: %b$fg[white]%d"

      ##
      ## misc options
      ##

      setopt correct prompt_subst
      setopt interactive_comments
      unsetopt nomatch
      setopt sh_word_split # for closer to posix

      # from https://unix.stackexchange.com/a/157773/319760
      setopt auto_pushd pushd_minus pushd_silent

      ##
      ## other files
      ##

      source "${./.}/zsh-terminfo.zsh"
      source "${./.}/zsh-bindings.zsh"
      source "${./.}/zsh-theme.zsh"

      ##
      ## MOTD
      ##

      () {
          local fortune="$HOME/.local/fortunes"
          echo
          fortune "$fortune" | cowsay -n
      }
    '';

    shellAliases = {
      "$" = " ";
      "@" = "tunnel-run ";
      "@@" = ''tunnel-run sh -c "exec \$SHELL --login"'';
      "," = "tunnel-run locally ";

      #
      # args
      #
      ls = "ls --color=auto -FhH";
      sudo = "sudo -E ";
      less = "less -SR";
      rm = "rm -I";
      tree = "tree -CF";
      rclone = "rclone --progress --transfers 16";

      diff = "diff --color=auto";
      grep = "grep --color=auto";
      ip = "ip --color=auto";
      dd = "dd bs=1M status=progress";
      watch = "watch --color ";

      ninja = "nice -n19 -- ninja";
      make = "nice -n19 -- make";

      #
      # new commands
      #
      tmux-ssh = ''() { ssh "$@" -t "tmux attach || tmux new" }'';
      what-is-my-ip = ''dig +short @1.1.1.1 ch txt whoami.cloudflare +time=3 | tr -d \"'';
      left-handed = "swaymsg input type:pointer left_handed enabled";
      right-handed = "swaymsg input type:pointer left_handed disabled";
      cdtemp = "cd $(mktemp -d)";
      dcc = "clang $DFLAGS";
      "d++" = "clang++ -std=c++14 $DFLAGS";

      home-manager-zsh = "ZDOTDIR=$(home-manager build --no-out-link)/home-files zsh";

      #
      # abbreviations
      #
      sc = "systemctl"; uc = "systemctl --user";
      jc = "journalctl"; ujc = "journalctl --user";
      ll = "ls -Al";

      isatty = ''(){ script --return --quiet --flush --command "$(printf "%q " "$@")" /dev/null } '';
    };

    localVariables = {
      ZSH_AUTOSUGGEST_STRATEGY = "completion";
      ZSH_AUTOSUGGEST_USE_ASYNC = "1";
      DFLAGS = ''
        -Wall -Wextra -pedantic -O2 -Wshadow -Wformat=2 -Wfloat-equal
        -Wconversion -Wshift-overflow -Wcast-qual -Wcast-align -D_GLIBCXX_DEBUG
        -D_GLIBCXX_DEBUG_PEDANTIC -D_FORTIFY_SOURCE=2 -fsanitize=address
        -fsanitize=undefined -fno-sanitize-recover=undefined,integer -fstack-protector
        -Wno-unused-result -DL -g
      '';
    };

    plugins = [
      {
        name = "async";
        src = inputs.mafredri-zsh-async;
      }
      {
        name = "auto-venv";
        src = pkgs.writeTextDir "auto-venv.plugin.zsh" (builtins.readFile ./auto-venv.plugin.zsh);
      }
    ];
  };
}
