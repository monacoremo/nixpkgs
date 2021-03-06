{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, arpack
, bison
, blas
, cmake
, flex
, fop
, glpk
, gmp
, lapack
, libxml2
, libxslt
, pkg-config
, python3
, sourceHighlight
, suitesparse
, xmlto
}:

stdenv.mkDerivation rec {
  pname = "igraph";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "igraph";
    repo = pname;
    rev = version;
    sha256 = "sha256-i6Zg6bfHZ9NHwqCouX9m9YqD0VtiWW8DEkxS0hdUyIE=";
  };

  patches = [
    (fetchpatch {
      name = "pkg-config-paths.patch";
      url = "https://github.com/igraph/igraph/commit/980521cc948777df471893f7b6de8f3e3916a3c0.patch";
      sha256 = "0mbq8v5h90c3dhgmyjazjvva3rn57qhnv7pkc9hlbqdln9gpqg0g";
    })
  ];

  # Normally, igraph wants us to call bootstrap.sh, which will call
  # tools/getversion.sh. Instead, we're going to put the version directly
  # where igraph wants, and then let autoreconfHook do the rest of the
  # bootstrap. ~ C.
  postPatch = ''
    echo "${version}" > IGRAPH_VERSION
  '' + lib.optionalString stdenv.isAarch64 ''
    # https://github.com/igraph/igraph/issues/1694
    substituteInPlace tests/CMakeLists.txt \
      --replace "igraph_scg_grouping3" "" \
      --replace "igraph_scg_semiprojectors2" ""
  '';

  outputs = [ "out" "dev" "doc" ];

  nativeBuildInputs = [
    cmake
    fop
    libxml2
    libxslt
    pkg-config
    python3
    sourceHighlight
    xmlto
  ];

  buildInputs = [
    arpack
    bison
    blas
    flex
    glpk
    gmp
    lapack
    libxml2
    suitesparse
  ];

  cmakeFlags = [
    "-DIGRAPH_USE_INTERNAL_BLAS=OFF"
    "-DIGRAPH_USE_INTERNAL_LAPACK=OFF"
    "-DIGRAPH_USE_INTERNAL_ARPACK=OFF"
    "-DIGRAPH_USE_INTERNAL_GLPK=OFF"
    "-DIGRAPH_USE_INTERNAL_CXSPARSE=OFF"
    "-DIGRAPH_USE_INTERNAL_GMP=OFF"
    "-DIGRAPH_GLPK_SUPPORT=ON"
    "-DIGRAPH_GRAPHML_SUPPORT=ON"
    "-DIGRAPH_ENABLE_LTO=ON"
    "-DIGRAPH_ENABLE_TLS=ON"
    "-DBUILD_SHARED_LIBS=ON"
  ];

  doCheck = true;

  preCheck = ''
    # needed to find libigraph.so
    export LD_LIBRARY_PATH="$PWD/src"
  '';

  postInstall = ''
    mkdir -p "$out/share"
    cp -r doc "$out/share"
  '';

  meta = with lib; {
    description = "The network analysis package";
    homepage = "https://igraph.org/";
    license = licenses.gpl2Plus;
    platforms = platforms.all;
    maintainers = with maintainers; [ MostAwesomeDude dotlambda ];
  };
}
