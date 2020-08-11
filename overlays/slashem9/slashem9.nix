{ stdenv, lib,fetchFromGitHub, writeScript,
  coreutils, ncurses, gzip, flex, bison, less, bash, git, pkg-config }:

let
  platform =
    if stdenv.hostPlatform.isUnix then "unix"
    else throw "Unknown platform for SLASH'EM: ${stdenv.hostPlatform.system}";
  userDir = "~/.config/slashem";
  binPath = lib.makeBinPath [ coreutils less ];
  configFile = ./slashem9rc;
  startup = writeScript "slashem9.wrapper" ''
    #!${bash}/bin/bash

    mkdir -p ${userDir}/save
    cd ${userDir}
    cp -an @HACKDIR@/{perm,xlogfile} .
    cp -af @HACKDIR@/{nhdat,slashem9} .
    chmod u+r *
    chmod u+w perm xlogfile
    chmod u+x slashem9 save

    if ! [[ -f ~/.slashem9rc ]]; then
      cat ${configFile} > ~/.slashem9rc
      echo "No ~/.slashem9rc found. Creating a default one. Enter to continue..."
      read
    fi
    exec ./slashem9 "$@"
  '';


in stdenv.mkDerivation rec {
  version = "2020-04-12";
  name = "slashem9-${version}";

  src = fetchFromGitHub {
    owner = "moon-chilled";
    repo = "slashem9";
    rev = "d5b15eee399485fce234b29e4a31ff1e88106b9c";
    sha256 = "00k3asj16fqywknpns9laa8d8jzlzrj33hm4mvh1mqygij75j32b";
  };

  buildInputs = [ ncurses ];
  nativeBuildInputs = [ flex bison git pkg-config ];

  postPatch = ''
    # Unicode character for rocks -- placeholder until per-object glyph
    # configuration is supported.
    sed -E "
      /iflags.travelcc.x =/ i oc_syms[ROCK_CLASS] = 0x25d5;
    " -i src/options.c
  '';

  makeFlags = [ "PREFIX=$(out)" "HACKDIR=$(out)/share/slashem9" "LEX=flex" ];
  enableParallelBuilding = true;

  # slashem9 comes with a launcher script that, basically:
  # - initializes HACKPAGER from PAGER if not set
  # - checks that the result is runnable and unsets both if not
  # - checks for environment variables to enable valgrind, gdb, or lldb and tweaks the invokation accordingly
  # - cds into HACKDIR and runs ./slashem9
  # We need to replace it with one that gives the player a local copy of HACKDIR,
  # since that's also where the save files and high scores are stored, so we
  # don't want it in /nix. For now we just give each player their own copy rather
  # than try to have a shared high score file/bones directory.
  postInstall = ''
    sed -E "
      s,@HACKDIR@,$out/share/slashem9,g
    " ${startup} > $out/bin/slashem9
    chmod a+x $out/bin/slashem9
  '';

  meta = with stdenv.lib; {
    description = "Super Lots Added Stuff Hack -- Extended Magic, a Nethack variant";
    homepage = http://nethack.org/;
    license = "nethack";
    platforms = platforms.unix;
    maintainers = with maintainers; [ ToxicFrog ];
  };
}
