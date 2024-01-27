{ lib, beamPackages
, fetchFromGitHub
, file, cmake
, nixosTests, writeText, findutils
, ...
}:

beamPackages.mixRelease rec {
  pname = "matrix2051";
  version = "0.1.0-2ee9da0";

  src = fetchFromGitHub {
    owner = "progval";
    repo = "matrix2051";
    rev = "2ee9da0a610233bf113eb22cb74927e8a083bda8";
    hash = "sha256-0Xl9li7DPf2Du0adkm5+9B/gznwFkJ2qCbRAWUOkkJk=";
  };

  mixNixDeps = import ./matrix2051-mixdeps.nix {
    inherit beamPackages lib;
  };

  meta = with lib; {
    description = "IRCv3 client to Matrix homeserver proxy";
    homepage = "https://github.com/progval/matrix2051";
    license = licenses.agpl3;
    # maintainers = with maintainers; [ picnoir yuka kloenk yayayayaka ];
    platforms = platforms.unix;
  };
}
