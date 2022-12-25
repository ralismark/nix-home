{ stdenv
, fetchzip
}:
stdenv.mkDerivation {
  # via <https://github.com/archlinux/svntogit-community/tree/packages/ttf-droid/trunk>

  pname = "droid-fonts";
  version = "20121017";

  src = fetchzip {
    url = "https://sources.archlinux.org/other/community/ttf-droid/ttf-droid-20121017.tar.xz";
    hash = "sha256-sNaJnbOtrUo7qcWhK65b7ARFdUOzOWFpA/RPPkii7Dk=";
  };

  installPhase = ''
    install -Dt $out/share/fonts/droid -m644 *.ttf
  '';

  # TODO fontconfig things
}
