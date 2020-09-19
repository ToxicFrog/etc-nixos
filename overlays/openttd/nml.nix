{ stdenv, fetchFromGitHub, python3Packages }:

python3Packages.buildPythonApplication rec {
  pname = "openttd-nml";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "OpenTTD";
    repo = "nml";
    rev = version;
    sha256 = "0pggs1xpdm402xss6z5csj5yy2dffly83wgkvmsg7lf3hf3n1j3r";
  };

  propagatedBuildInputs = with python3Packages; [ply pillow];

  meta = with stdenv.lib; {
    description = "Compiler for OpenTTD NML files";
    homepage    = "http://openttdcoop.org/";
    license     = licenses.gpl2;
    maintainers = with maintainers; [ ToxicFrog ];
  };
}
