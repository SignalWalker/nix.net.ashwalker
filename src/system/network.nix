{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  wg = config.networking.wireguard;
in {
  options = with lib; {
    networking.wireguard.tunneledUsers = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };
  disabledModules = [];
  imports = lib.signal.fs.path.listFilePaths ./network;
  config = {
    systemd.network.networks."eth" = {
      networkConfig.Address = ["5.161.136.2/32" "2a01:4ff:f0:b30::1/64"];
      routes = [
        {
          Gateway = "172.31.1.1";
        }
        {
          Gateway = "fe80::1";
        }
      ];
    };

    networking.wireguard.tunnels."wg-torrent" = let
      table = 47107;
    in {
      enable = true;
      addresses = [
        "10.167.26.8"
        "fd7d:76ee:e68f:a993:b560:c12b:27ba:5557"
      ];
      privateKeyFile = "/var/lib/wireguard/wg-torrent.sign";
      dns = ["10.128.0.1" "fd7d:76ee:e68f:a993::1"];
      inherit table;
      port = table;
      priority = 20;
      mtu = 1320;
      peer = {
        publicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
        presharedKeyFile = "/var/lib/wireguard/wg-torrent.psk";
        endpoint = "198.44.136.254:47107";
        allowedIps = ["0.0.0.0/0" "::/0"];
      };
      activationPolicy = "up";
      routingPolicyRules = foldl' (acc: user:
        acc
        ++ [
          {
            User = user;
            Table = table;
            Priority = 10;
            Family = "both";
          }
          {
            Table = "main";
            User = user;
            Priority = 9;
            SuppressPrefixLength = 0;
            Family = "both";
          }
          # exempt local addresses
          {
            To = "127.0.0.0/8";
            User = user;
            Priority = 6;
          }
        ]) [] (config.networking.wireguard.tunneledUsers);
    };

    systemd.tmpfiles.rules = [
      "z ${wg.tunnels."wg-torrent".privateKeyFile} 0400 systemd-network systemd-network"
      "z ${wg.tunnels."wg-torrent".peer.presharedKeyFile} 0400 systemd-network systemd-network"
    ];
  };
  meta = {};
}
