let
  srv-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkFAhZAMIcFMiOD8MaHZgQLANcDWy/wCFBaAQQ+TPE2";
  ash = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFqg4NlJu7u1pcCel3EZshVwUxIfwpsh2fxhaQlLAar";
  keys = [srv-host ash];
in {
  "mailPasswordAsh.age".publicKeys = keys;
  "mailPasswordDaemon.age".publicKeys = keys;
}