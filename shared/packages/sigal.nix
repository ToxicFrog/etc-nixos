{ stdenv
, lib
, python3
, fetchPypi
, ffmpeg
}:

python3.pkgs.buildPythonApplication rec {
  pname = "sigal";
  version = "2.4";
  format = "pyproject";

  src = fetchPypi {
    inherit version pname;
    hash = "sha256-pDTaqtqfuk7tACkyaKClTJotuVcTKli5yx1wbEM93TM=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    # install_requires
    jinja2
    markdown
    pillow
    pilkit
    click
    blinker
    natsort
    # extras_require
    brotli
    feedgenerator
    zopfli
    cryptography

    setuptools # needs pkg_resources
    setuptools-scm
  ];

  nativeCheckInputs = [
    ffmpeg
  ] ++ (with python3.pkgs; [
    pytestCheckHook
  ]);

  disabledTests = lib.optionals stdenv.isDarwin [
    "test_nonmedia_files"
  ];

  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [ ffmpeg ]}"
  ];

  meta = with lib; {
    description = "Yet another simple static gallery generator";
    homepage = "http://sigal.saimon.org/";
    license = licenses.mit;
    maintainers = with maintainers; [ domenkozar matthiasbeyer ];
  };
}
