{ lib, buildNpmPackage, fetchFromGitHub, source ? null }:

buildNpmPackage rec {
  pname = "mstream";
  version = "2023.11";

  src = if source != null then source else fetchFromGitHub {
    owner = "IrosTheBeggar";
    repo = pname;
    rev = "06f15420d8e0bcb23d9d698c866c184579ab9f14";
    hash = "sha256-I17zhLiviKB8O1JRLAdTjTKysOp27YgWWkKU0D5ZZUU=";
  };

  patches = [ ./mstream-add-all.patch ];

  postPatch = ''
    cp -v ${./mstream.lock} package-lock.json
  '';

  npmDepsHash = "sha256-7i8O44lUBSPrcroyvG4eLz7jfaNzW7SZmxyQOt3MybI=";
  dontNpmBuild = true;

  # The prepack script runs the build script, which we'd rather do in the build phase.
  # npmPackFlags = [ "--ignore-scripts" ];

  # NODE_OPTIONS = "--openssl-legacy-provider";

  meta = with lib; {
    description = "A music streaming server with support for filesystem browsing";
    homepage = "https://mstream.io";
    # license = licenses.gpl3Only;
    # maintainers = with maintainers; [ winter ];
  };
}
