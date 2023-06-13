#include <znc/main.h>
#include <znc/Modules.h>
#include <znc/User.h>
#include <fstream>

using namespace std;

class CLoadPassFile : public CModule {
public:
  MODCONSTRUCTOR(CLoadPassFile) {}

  bool OnLoad(const CString& sPassFilePath, CString& sMessage) override {
    string hash, salt;
    ifstream passfile (sPassFilePath);
    getline (passfile, hash);
    getline (passfile, salt);
    passfile.close();
    GetUser()->SetPass(hash, CUser::HASH_SHA256, salt);
    return true;
  }
};

USERMODULEDEFS(CLoadPassFile, t_s("Load user password from a file"))
