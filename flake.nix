{
  description = "NixOS config for ashwalker.net";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sysbase = {
      url = github:signalwalker/nix.sys.base;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.alejandra.follows = "alejandra";
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
            };
            imports = [./nixos-module.nix];
            config = {
            };
          };
        };
      };
      homeConfigurations."ash" = {
        config,
        lib,
        ...
      }: {
        imports = [inputs.homebase.homeManagerModules.default];
        config = {};
      };
      nixosModules."hermes" = {
        lib,
        pkgs,
        ...
      }: {
        options = {
          services.akkoma.src = mkOption {
            type = types.path;
            default = inputs.akkoma;
            readOnly = true;
          };
          services.grocy.src = mkOption {
            type = types.path;
            default = inputs.grocy-src;
            readOnly = true;
          };
        };
        imports = [
          inputs.sysbase.nixosModules.default
          inputs.agenix.nixosModules.age
          inputs.simple-nixos-mailserver.nixosModules.mailserver
          inputs.ashwalker-net.nixosModules.default

          ./nixos-module.nix

          ./hw/hermes.nix
        ];
        config = {
          networking.hostName = "ashwalker";
          networking.domain = "net";
          home-manager.users = self.homeConfigurations;
          nixpkgs.overlays = [
            inputs.agenix.overlays.default
          ];

          services.mediawiki.extensions = {
            CSS = inputs.mediawiki-css;
          };

          services.matrix-conduit.package = inputs.conduit.packages.${pkgs.system}.default;
        };
      };
      nixosConfigurations."hermes" = std.nixosSystem {
        system = null; # set in `config.nixpkgs.hostPlatform`
        modules = [
          self.nixosModules."hermes"
        ];
        lib = std.extend (final: prev: {
          signal = inputs.homelib.lib;
        });
      };
      deploy.nodes."hermes" = {
        hostname = "ashwalker.net";
        remoteBuild = false;
        profiles.system = {
          sshUser = "ash";
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."hermes";
        };
      };
    };
}
