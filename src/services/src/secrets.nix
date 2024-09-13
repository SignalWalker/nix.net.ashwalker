let
  srv-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL96LFIgKgNXAQPl9y/EtWwxBZtRatxGk535ZxDy/IU5 root@exampleHost";
  ash = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFqg4NlJu7u1pcCel3EZshVwUxIfwpsh2fxhaQlLAar";
  keys = [srv-host ash];
in {
  "srcNetworkKey.age".publicKeys = keys;
  "srcServiceKey.age".publicKeys = keys;
  "srcWebhookKey.age".publicKeys = keys;
  "srcMailKey.age".publicKeys = keys;
}