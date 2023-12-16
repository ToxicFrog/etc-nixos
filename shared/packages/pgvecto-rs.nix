{ lib, stdenv, fetchurl, dpkg }:

let
  # postgres major version
  psql = "15";
  # pgvecto.rs hashes for different major versions of postgres
  versionHashes = {
    "14" = "sha256-8YRC1Cd9i0BGUJwLmUoPVshdD4nN66VV3p48ziy3ZbA=";
    "15" = "sha256-IVx/LgRnGyvBRYvrrJatd7yboWEoSYSJogLaH5N/wPA=";
  };
in super.stdenv.mkDerivation rec {
  pname = "pgvecto-rs";
  version = "0.1.11";

  buildInputs = [ dpkg ];

  src = fetchurl {
    url = "https://github.com/tensorchord/pgvecto.rs/releases/download/v${version}/vectors-pg${major}-v${version}-x86_64-unknown-linux-gnu.deb";
    hash = versionHashes."${major}";
  };

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out
    dpkg -x $src $out
    install -D -t $out/lib $out/usr/lib/postgresql/${major}/lib/*.so
    install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.sql
    install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.control
    rm -rf $out/usr
  '';

  meta = {
    description = "pgvecto.rs postgres extension";
    homepage = "https://github.com/tensorchord/pgvecto.rs";
  };
}
