final: prev: {
  factor-lang = prev.factor-lang.overrideAttrs (old: {
    version = "0.99";
    src = prev.fetchFromGitHub {
      owner = "factor"; repo = "factor";
      rev = "e70d0fd819eb8b9d5a15213428df22a73ce6b210";
      sha256 = "sha256-cQl1jxhiNt9apAQNq1ICWkFlfr1MiRVmAPEZHdJZ6/o=";
    };
    bootstrap = prev.fetchurl {
      url = "https://downloads.factorcode.org/images/master/boot.unix-x86.64.image";
      sha256 = "sha256-jVy9ylkDPVkl51RraNSF9/PIpSSCVQh1kDgybHgLGGU=";
    };
    preBuild = ''
      cp $bootstrap boot.unix-x86.64.image
    '';
    patches = [];
  });
}
