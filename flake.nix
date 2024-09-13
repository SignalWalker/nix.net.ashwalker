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
    nixinate = {
      url = "github:matthewcroughan/nixinate";
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
      url = "git+https://git.ashwalker.net/Ash/ashwalker.net";
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
    akkoma-fe = {
      url = "git+https://akkoma.dev/AkkomaGang/akkoma-fe";
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
    # grocy-src = {
    #   url = "github:grocy/grocy";
    #   flake = false;
    # };
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

      homeConfigurations."ash" = {
        config,
        lib,
        ...
      }: {
        imports = [inputs.homebase.homeManagerModules.default];
        config = {};
      };

      nixosModules."hermes" = {
        config,
        lib,
        pkgs,
        ...
      }: {
        options = with lib; {
          services.akkoma = {
            src = mkOption {
              type = types.path;
              default = inputs.akkoma;
              readOnly = true;
            };
            akkoma-fe-src = mkOption {
              type = types.path;
              default = inputs.akkoma-fe;
              readOnly = true;
            };
          };
          # services.grocy.src = mkOption {
          #   type = types.path;
          #   default = inputs.grocy-src;
          #   readOnly = true;
          # };
        };
        imports = [
          inputs.sysbase.nixosModules.default
          inputs.agenix.nixosModules.age
          inputs.simple-nixos-mailserver.nixosModules.mailserver
          inputs.ashwalker-net.nixosModules.default
          inputs.funkwhale.nixosModules.default

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

          signal.machines.terra.nix.build.enable = lib.mkForce false;

          signal.network.wireguard.networks."wg-signal" = {
            privateKeyFile = "/var/lib/wireguard/wg-signal.sign";
          };

          signal.machine.signalName = "hermes";

          systemd.tmpfiles.rules = [
            "z ${config.signal.network.wireguard.networks.wg-signal.privateKeyFile} 0400 systemd-network systemd-network"
          ];
        };
      };

      nixosConfigurations."hermes" = std.nixosSystem {
        system = null; # set in `config.nixpkgs.hostPlatform`
        modules = [
          self.nixosModules."hermes"
          {
            _module.args.nixinate = {
              host = "fd24:fad3:8246::3";
              sshUser = "root";
              buildOn = "local";
              substituteOnTarget = true;
              hermetic = false;
            };
          }
        ];
        lib = std.extend (final: prev: {
          signal = inputs.homelib.lib;
        });
      };

      deploy = {
        nodes = {
          "hermes" = {
            hostname = "hermes.ashwalker.net";
            # remoteBuild = false;
            sshUser = "root";
            sshOpts = ["-oControlMaster=no"];
            profilesOrder = ["system"];
            profiles = {
              system = {
                user = "root";
                path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."hermes";
              };
            };
          };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
    };
}
