{
  description = "NixOS config for ashwalker.net";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    alejandra = {
      url = github:kamadorueda/alejandra;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sysbase = {
      url = github:signalwalker/nix.sys.base;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.alejandra.follows = "alejandra";
      inputs.homebase.follows = "homebase";
      inputs.homelib.follows = "homelib";
    };
    homelib = {
      url = github:signalwalker/nix.home.lib;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.alejandra.follows = "alejandra";
      inputs.home-manager.follows = "home-manager";
    };
    homebase = {
      url = github:signalwalker/nix.home.base;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.alejandra.follows = "alejandra";
      inputs.homelib.follows = "homelib";
      inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # testing
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secrets
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # pkgs
    ashwalker-net = {
      url = "github:signalwalker/net.ashwalker";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # music
    funkwhale = {
      url = "github:mmai/funkwhale-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # activitypub
    pleroma = {
      url = "git+https://git.pleroma.social/pleroma/pleroma/";
      flake = false;
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }:
    with builtins; let
      std = nixpkgs.lib;
      hlib = inputs.homelib.lib;
      signal = hlib.signal;
      sys = hlib.sys;
      self' = signal.flake.resolve {
        flake = self;
        name = "sys.ashwalker-net";
      };
      systems = ["x86_64-linux" "aarch64-linux"];
      argsFor = std.genAttrs systems (system:
        sys.configuration.genArgsFromFlake {
          flake' = self';
          signalModuleName = "default";
          crossSystem = system;
        });
    in {
      formatter = std.mapAttrs (system: pkgs: pkgs.default) inputs.alejandra.packages;
      signalModules.default = {
        name = "sys.net.ashwalker";
        dependencies = signal.flake.set.toDependencies {
          flakes = inputs;
          filter = [];
          outputs = {
            sysbase.nixosModules = ["default"];
            ashwalker-net.nixosModules = ["default"];
            agenix.nixosModules = ["age"];
          };
        };
        outputs = dependencies: {
          nixosModules = {lib, ...}: {
            options = with lib; {
              services.pleroma.src = mkOption {
                type = types.path;
                default = dependencies.pleroma;
                readOnly = true;
              };
            };
            imports = [./nixos-module.nix];
            config = {};
          };
        };
      };
      packages = std.genAttrs systems (system: let
        gen = inputs.nixos-generators;
        args = argsFor.${system};
        modules =
          args.modules
          ++ [
            ({...}: {
              networking.hostName = "ashwalker";
              networking.domain = "local";
            })
          ];
      in {
        raw = gen.nixosGenerate {
          inherit (args) system lib pkgs;
          inherit modules;
          format = "raw-efi";
        };
        qcow = gen.nixosGenerate {
          inherit (args) system lib pkgs;
          inherit modules;
          format = "qcow";
        };
        vm = gen.nixosGenerate {
          inherit (args) system lib pkgs;
          inherit modules;
          format = "vm";
        };
      });
      apps = std.genAttrs systems (system: let
        hostName = "ashwalker";
      in {
        "${hostName}-vm" = {
          type = "app";
          program = "${self.packages.${system}.vm}/bin/run-${hostName}-vm";
        };
        default = self.apps.${system}.vm;
      });
    };
}
