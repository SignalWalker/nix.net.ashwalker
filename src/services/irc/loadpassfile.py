import znc

class loadpassfile(znc.Module):
    description = "Load user password from a file"
    module_types = [znc.CModInfo.UserModule]
    has_args = True

    def OnLoad(self, args, message):
        with open(args) as passfile:
            hash = passfile.readline()
            salt = passfile.readline()
            znc.GetUser().SetPass(hash, znc.CUser.HASH_SHA256, salt)
            return True
