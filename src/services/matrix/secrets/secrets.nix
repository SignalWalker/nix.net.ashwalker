let
  srv-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL96LFIgKgNXAQPl9y/EtWwxBZtRatxGk535ZxDy/IU5 root@exampleHost";
  ash = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFqg4NlJu7u1pcCel3EZshVwUxIfwpsh2fxhaQlLAar";
  keys = [srv-host ash];
in {
  "matrixDiscordEnvironmentFile.age".publicKeys = keys;
  "matrixDiscordDbPassword.age".publicKeys = keys;
}