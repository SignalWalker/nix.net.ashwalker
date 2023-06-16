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
      url = "github:signalwalker/nix.srv.funkwhale";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # activitypub
    akkoma = {
      url = "git+https://akkoma.dev/AkkomaGang/akkoma";
      flake = false;
    };
    # mail
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # wiki
    mediawiki-css = {
      url = "github:wikimedia/mediawiki-extensions-CSS";
      flake = false;
    };
    # matrix
    conduit = {
      url = "gitlab:famedly/conduit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # groceries
    grocy-src = {
      url = "github:grocy/grocy";
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
            simple-nixos-mailserver.nixosModules = ["mailserver"];
            funkwhale = {
              overlays = system: ["default" system];
              nixosModules = ["default"];
            };
          };
        };
        outputs = dependencies: {
          nixosModules = {
            lib,
            pkgs,
            ...
          }: {
            options = with lib; {
              services.akkoma.src = mkOption {
                type = types.path;
                default = dependencies.akkoma;
                readOnly = true;
              };
              services.grocy.src = mkOption {
                type = types.path;
                default = dependencies.grocy-src;
                readOnly = true;
              };
            };
            imports = [./nixos-module.nix];
            config = {
              services.mediawiki.extensions = {
                CSS = dependencies.mediawiki-css;
              };
              # services.matrix-conduit.package = dependencies.conduit.packages.${pkgs.system}.default;
            };
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
