self: super:

{
  ledger-autosync = self.python27Packages.buildPythonPackage rec {
    name = "ledger-autosync-${version}";
    version = "0.3.5";
    src = self.pkgs.fetchurl {
      url = "mirror://pypi/l/ledger-autosync/ledger-autosync-${version}.tar.gz";
      sha256 = "01pvk5if25ls61img6mphf8cxgc5mflprqvjhrnk4gagdqk04dpd";
    };

    propagatedBuildInputs = with self.pkgs; [ python27Packages.ofxclient ];

    buildInputs = with self.pkgs; [
      python27Packages.mock
      python27Packages.nose
      fuzzywuzzy
      # Used at runtime to translate ofx entries to the ledger
      # format. In fact, user could use either ledger or hledger.
      which
      ledger
    ];

    # Tests are disable since they require hledger and python-ledger
    doCheck = false;
  };
  fuzzywuzzy = self.python27Packages.buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "fuzzywuzzy";
    version = "0.16.0";

    src = self.python27Packages.fetchPypi {
      inherit pname version;
      sha256 = "0kldif0d393p2wrp80q73mj5z1xpz83zrfrhbf489zsdfk92436l";
    };

    checkInputs = with self.python27Packages; [
      hypothesis pycodestyle pytest
    ];

    checkPhase = ''
      py.test
    '';
  };
}
