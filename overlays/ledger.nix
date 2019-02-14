self: super:

{
  ledger-autosync = self.python27Packages.buildPythonPackage rec {
    name = "ledger-autosync-${version}";
    version = "0.3.5";
    src = self.pkgs.fetchurl {
      url = "mirror://pypi/l/ledger-autosync/ledger-autosync-${version}.tar.gz";
      sha256 = "01pvk5if25ls61img6mphf8cxgc5mflprqvjhrnk4gagdqk04dpd";
    };

    propagatedBuildInputs = with self.pkgs; [
      python27Packages.ofxclient
      fuzzywuzzy
      which
      hledger  # or ledger
    ];

    buildInputs = with self.pkgs; [
      python27Packages.mock
      python27Packages.nose
    ];

    # Tests are disable since they require hledger and python-ledger
    doCheck = false;
  };
  fuzzywuzzy = self.python27Packages.buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "fuzzywuzzy";
    version = "0.17.0";

    src = self.python27Packages.fetchPypi {
      inherit pname version;
      sha256 = "0qid283ysgzn3pm6pdm9dy9mghsa511dl5md80fwgq80vd3xwjbg";
    };

    propagatedBuildInputs = [ self.python27Packages.python-Levenshtein ];

    checkInputs = with self.python27Packages; [
      hypothesis pycodestyle pytest
    ];

    checkPhase = ''
      py.test
    '';
  };
}
