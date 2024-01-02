{ lib
, fetchFromGitHub
, python3
, bash
}:

python3.pkgs.buildPythonApplication rec {
  pname = "marcel";
  version = "0.20.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "geophile";
    repo = "marcel";
    rev = "refs/tags/v${version}";
    hash = "sha256-DlpjE0RTn2zdTkSKXGvuZXBk8R6ZKrhRe8U7xchyauo=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    dill
    psutil
    bash
    setuptools
  ];

  # The tests use sudo and try to read/write $HOME/.local/share/marcel and /tmp
  doCheck = false;

  postFixup = ''
    substituteInPlace $out/bin/marcel \
        --replace python3 ${python3}/bin/python3
    wrapProgram $out/bin/marcel \
        --prefix PATH : "$program_PATH:${bash}/bin" \
        --prefix PYTHONPATH : "$program_PYTHONPATH"
    '';

  meta = with lib; {
    description = "A modern shell";
    homepage = "https://github.com/geophile/marcel";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ kud ];
    mainProgram = "marcel";
  };
}
