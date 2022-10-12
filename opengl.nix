# Adapted from <https://github.com/guibou/nixGL/blob/main/nixGL.nix#L130-L157>
{ config, pkgs, ... }:
with config;
let
  inherit (pkgs) lib;

  mesa-drivers = [ pkgs.mesa.drivers ];
  intel-drivers = [ pkgs.intel-media-driver pkgs.vaapiIntel ];
  libvdpau = [ pkgs.libvdpau-va-gl ];
  glxindirect = pkgs.runCommand "mesa_glxindirect" {} ''
    mkdir -p $out/lib
    ln -s ${pkgs.mesa.drivers}/lib/libGLX_mesa.so.0 $out/lib/libGLX_indirect.so.0
  '';
in {
  home.sessionVariables = {
    LIBGL_DRIVERS_PATH = lib.makeSearchPathOutput "lib" "lib/dri" mesa-drivers;
    LIBVA_DRIVERS_PATH = lib.makeSearchPathOutput "out" "lib/dri" intel-drivers;
    __EGL_VENDOR_LIBRARY_FILENAMES = (lib.makeSearchPathOutput "out" "share/glvnd/egl_vendor.d/50_mesa.json" mesa-drivers) + "\${__EGL_VENDOR_LIBRARY_FILENAMES:+:$__EGL_VENDOR_LIBRARY_FILENAMES}";
    LD_LIBRARY_PATH = (lib.concatStringsSep ":" [
      (lib.makeLibraryPath mesa-drivers)
      (lib.makeSearchPathOutput "lib" "lib/vdpau" libvdpau)
      "${glxindirect}/lib"
      (lib.makeLibraryPath [pkgs.libglvnd])
    ]) + "\${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}";
  };
}
