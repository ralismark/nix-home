{
  description = "Home Manager configuration";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # zsh plugins
    mafredri-zsh-async = {
      url = "github:mafredri/zsh-async";
      flake = false;
    };

    nix-index-database.url = "github:Mic92/nix-index-database";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;

        overlays = [
          (self: super: {
            numix-reborn-icon-themes = self.callPackage ./packages/numix-reborn-icon-themes.nix {};
            # based on <https://github.com/oberon-manjaro/adapta-maia-theme/blob/master/PKGBUILD>
            adapta-maia-theme = super.adapta-gtk-theme.overrideAttrs (final: prev: {
              pname = "adapta-maia-theme";
              postPatch = ''
                ${prev.postPatch or ""}
                find . -type f -name '*.*' -exec sed -i \
                  "s/#00BCD4/#16a085/Ig" {} \;
                find \
                  ./extra/gedit/adapta.xml \
                  ./extra/plank/dock.theme \
                  ./extra/telegram/dark/colors.tdesktop-theme \
                  ./extra/telegram/light/colors.tdesktop-theme \
                  ./gtk/asset/assets-gtk2.svg.in \
                  ./gtk/asset/assets-gtk3.svg.in \
                  ./gtk/asset/assets-clone/z-depth-1.svg \
                  ./gtk/asset/assets-clone/z-depth-2.svg \
                  ./gtk/gtk-2.0/colors.rc.in \
                  ./gtk/gtk-2.0/colors-dark.rc.in \
                  ./gtk/gtk-2.0/common.rc \
                  ./gtk/gtk-2.0/common-eta.rc \
                  ./gtk/sass/common/_colors.scss \
                  ./m4/adapta-color-scheme.m4 \
                  ./shell/asset/assets-cinnamon/ \
                  ./shell/asset/assets-gnome-shell/ \
                  ./shell/asset/assets-xfce/ \
                  ./shell/sass/common/_colors.scss \
                  ./shell/sass/gnome-shell/3.24/_extension-workspaces-to-dock.scss \
                  ./shell/sass/gnome-shell/3.26/_extension-workspaces-to-dock.scss \
                  ./shell/xfce-notify-4.0/gtkrc \
                  ./wm/asset/assets-metacity/ \
                  ./wm/asset/assets-openbox/ \
                  ./wm/asset/assets-xfwm/ \
                  ./wm/metacity-1/metacity-theme-2.xml \
                  ./wm/openbox-3/themerc \
                  ./wm/openbox-3/themerc-nokto \
                  ./wm/xfwm4/themerc -type f -print | xargs sed -i -e \
                  's/#2196F3/#38a8a3/Ig'  -e \
                  's/#03A9f4/#299984/Ig'
              '';
              postInstall = ''
                ${prev.postInstall or ""}

                # rename folders
                mv $out/share/themes/Adapta{,-Maia}
                mv $out/share/themes/Adapta-Nokto{,-Maia}
                mv $out/share/themes/Adapta-Eta{,-Maia}
                mv $out/share/themes/Adapta-Nokto-Eta{,-Maia}

                # modify index.theme
                sed -Ee 's/Adapta(-Nokto)?(-Eta)?$/\0-Maia/' -i $out/share/themes/*/index.theme
              '';
            });
            pantheon.elementary-files = super.pantheon.elementary-files.overrideAttrs (final: prev: {
              mesonFlags = (prev.mesonFlags or []) ++ [ "-Dwith-zeitgeist=disabled" ];
            });
          })
        ];
      };
    in
    rec {
      formatter.${system} = pkgs.nixpkgs-fmt;

      apps.${system}.default = {
        type = "app";
        program = "${homeConfigurations.me.activationPackage}/activate";
      };

      packages.${system} = {
        default = homeConfigurations.me.activationPackage;

        inherit (pkgs) numix-reborn-icon-themes adapta-maia-theme;
      };

      homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix

          # per-system stuff
          (_: {
            # Automatically set some environment variables that will ease usage of
            # software installed with nix on non-NixOS linux
            targets.genericLinux.enable = true;

            # username
            home.username = "timmy";
          })
        ];

        # These are passed to home.nix
        extraSpecialArgs = {
          inherit inputs;
        };
      };
    };
}
