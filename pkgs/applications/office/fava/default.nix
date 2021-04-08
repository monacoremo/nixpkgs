{ lib, python3 }:

python3.pkgs.buildPythonApplication rec {
  pname = "fava";
  version = "1.18";

  src = python3.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "21336b695708497e6f00cab77135b174c51feb2713b657e0e208282960885bf5";
  };

  nativeBuildInputs = with python3.pkgs; [ setuptools-scm ];

  propagatedBuildInputs = with python3.pkgs; [
    Babel
    cheroot
    flaskbabel
    flask
    jinja2
    beancount
    click
    markdown2
    ply
    simplejson
    werkzeug
    jaraco_functools
  ];

  checkInputs = with python3.pkgs; [
    pytestCheckHook
  ];

  preCheck = ''
    export HOME=$TEMPDIR
  '';

  disabledTests = [
    # runs fava in debug mode, which tries to interpret bash wrapper as Python
    "test_cli"
  ];

  meta = {
    homepage = "https://beancount.github.io/fava";
    description = "Web interface for beancount";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ matthiasbeyer ];
  };
}
