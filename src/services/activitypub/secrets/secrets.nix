let
  srv-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJkq7D+tBr4IrT0eZhggfWOLxsM9l28vLoYt3ZTMsgHd host@ashwalker.net";
  ash = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFqg4NlJu7u1pcCel3EZshVwUxIfwpsh2fxhaQlLAar";
  keys = [srv-host ash];
in {
  "endpointKey.age".publicKeys = keys;
  "endpointSalt.age".publicKeys = keys;
  "liveViewSalt.age".publicKeys = keys;
  "repoKey.age".publicKeys = keys;
  "pushPublicKey.age".publicKeys = keys;
  "pushPrivateKey.age".publicKeys = keys;
  "jokenKey.age".publicKeys = keys;
  "activitypubDbPassword.age".publicKeys = keys;
  "meilisearchMasterKey.age".publicKeys = keys;
}