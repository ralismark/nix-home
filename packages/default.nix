self: super: {
  numix-reborn-icon-themes = self.callPackage ./numix-reborn-icon-themes.nix {};

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
}
