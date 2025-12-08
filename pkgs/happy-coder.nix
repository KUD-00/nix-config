{ lib, mkYarnPackage, fetchFromGitHub }:

mkYarnPackage rec {
  pname = "happy-coder";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "slopus";
    repo = "happy-cli";
    rev = "v${version}";
    sha256 = "0g4wdy21mswicqrr9wskdg5fl18dfn14ya0qqwlzif89f309fvch";
  };

  buildPhase = ''
    export HOME=$(mktemp -d)
    yarn --offline build
  '';

  meta = with lib; {
    description = "Happy Coder CLI";
    homepage = "https://github.com/slopus/happy-cli";
    license = licenses.mit;
    maintainers = [ ];
  };
}
