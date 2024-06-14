{ lib, buildNpmPackage, fetchFromGitHub, source ? null }:

buildNpmPackage rec {
  pname = "mstream";
  version = "5.12.2";

  src = if source != null then source else fetchFromGitHub {
    owner = "IrosTheBeggar";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-000zhLiviKB8O1JRLAdTjTKysOp27YgWWkKU0D5ZZUU=";
  };

  patches = [ ./mstream-add-all.patch ];

  postPatch = ''
    cp -v ${./mstream.lock} package-lock.json
  '';

  npmDepsHash = "sha256-6tV/VGDcNndtf78jCJdxDy8EAfBziLvjYmofCeTx0bw=";
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
