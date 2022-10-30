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
          (import ./packages)
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
          # ./opengl.nix # genericLinux
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
