#!/usr/bin/env bats

# shellcheck disable=SC2230

load ../node_modules/bats-support/load.bash
load ../node_modules/bats-assert/load.bash
load ./lib/test_utils

# TODO: check tests below you really adopt

setup_file() {
  PROJECT_DIR="$(realpath "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_DIR
  cd "$PROJECT_DIR"
  clear_lock git

  ASDF_DIR="$(mktemp -t <YOUR TOOL LC>-integration-tests.XXXX -d)"
  export ASDF_DIR

  get_lock git
  git clone \
    --branch=v0.10.2 \
    --depth=1 \
    https://github.com/asdf-vm/asdf.git \
    "$ASDF_DIR"
  clear_lock git
}

teardown_file() {
  clear_lock git
  rm -rf "$ASDF_DIR"
}

setup() {
  ASDF_<YOUR TOOL UC>_TEST_TEMP="$(mktemp -t <YOUR TOOL LC>-integration-tests.XXXX -d)"
  export ASDF_<YOUR TOOL UC>_TEST_TEMP
  ASDF_DATA_DIR="${ASDF_<YOUR TOOL UC>_TEST_TEMP}/asdf"
  export ASDF_DATA_DIR
  mkdir -p "$ASDF_DATA_DIR/plugins"

  # `asdf plugin add <YOUR TOOL LC> .` would only install from git HEAD.
  # So, we install by copying the plugin to the plugins directory.
  cp -R "$PROJECT_DIR" "${ASDF_DATA_DIR}/plugins/<YOUR TOOL LC>"
  cd "${ASDF_DATA_DIR}/plugins/<YOUR TOOL LC>"

  # shellcheck disable=SC1090,SC1091
  source "${ASDF_DIR}/asdf.sh"

  ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH="${ASDF_DATA_DIR}/installs/<YOUR TOOL LC>/ref-version-1-6"
  export ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH

  # optimization if already installed
  info "asdf install <YOUR TOOL LC> ref:version-1-6"
  if [ -d "${HOME}/.asdf/installs/<YOUR TOOL LC>/ref-version-1-6" ]; then
    mkdir -p "${ASDF_DATA_DIR}/installs/<YOUR TOOL LC>"
    cp -R "${HOME}/.asdf/installs/<YOUR TOOL LC>/ref-version-1-6" "${ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH}"
    rm -rf "${ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH}/<YOUR TOOL LC>"
    asdf reshim
  else
    get_lock git
    asdf install <YOUR TOOL LC> ref:version-1-6
    clear_lock git
  fi
  asdf local <YOUR TOOL LC> ref:version-1-6
}

teardown() {
  asdf plugin remove <YOUR TOOL LC> || true
  rm -rf "${ASDF_<YOUR TOOL UC>_TEST_TEMP}"
}

info() {
  echo "# ${*} …" >&3
}

@test "<YOUR TOOL LC>_configuration__without_<YOUR TOOL LC>deps" {
  # Assert package index is placed in the correct location
  info "<YOUR TOOL LC> refresh -y"
  get_lock git
  <YOUR TOOL LC> refresh -y
  clear_lock git
  assert [ -f "${ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH}/<YOUR TOOL LC>/packages_official.json" ]

  # Assert package installs to correct location
  info "<YOUR TOOL LC> install -y <YOUR TOOL LC>json@1.2.8"
  get_lock git
  <YOUR TOOL LC> install -y <YOUR TOOL LC>json@1.2.8
  clear_lock git
  assert [ -x "${ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH}/<YOUR TOOL LC>/bin/<YOUR TOOL LC>json" ]
  assert [ -f "${ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH}/<YOUR TOOL LC>/pkgs/<YOUR TOOL LC>json-1.2.8/<YOUR TOOL LC>json.<YOUR TOOL LC>" ]
  assert [ ! -x "./<YOUR TOOL LC>deps/bin/<YOUR TOOL LC>json" ]
  assert [ ! -f "./<YOUR TOOL LC>deps/pkgs/<YOUR TOOL LC>json-1.2.8/<YOUR TOOL LC>json.<YOUR TOOL LC>" ]

  # Assert that shim was created for package binary
  assert [ -f "${ASDF_DATA_DIR}/shims/<YOUR TOOL LC>json" ]

  # Assert that correct <YOUR TOOL LC>json is used
  assert [ -n "$(<YOUR TOOL LC>json -v | grep ' version 1\.2\.8')" ]

  # Assert that <YOUR TOOL LC> finds <YOUR TOOL LC> packages
  echo "import <YOUR TOOL LC>json" >"${ASDF_<YOUR TOOL UC>_TEST_TEMP}/test<YOUR TOOL LC>.<YOUR TOOL LC>"
  info "<YOUR TOOL LC> c -r \"${ASDF_<YOUR TOOL UC>_TEST_TEMP}/test<YOUR TOOL LC>.<YOUR TOOL LC>\""
  <YOUR TOOL LC> c -r "${ASDF_<YOUR TOOL UC>_TEST_TEMP}/test<YOUR TOOL LC>.<YOUR TOOL LC>"
}

@test "<YOUR TOOL LC>_configuration__with_<YOUR TOOL LC>deps" {
  rm -rf <YOUR TOOL LC>deps
  mkdir "./<YOUR TOOL LC>deps"

  # Assert package index is placed in the correct location
  info "<YOUR TOOL LC> refresh"
  get_lock git
  <YOUR TOOL LC> refresh -y
  clear_lock git
  assert [ -f "./<YOUR TOOL LC>deps/packages_official.json" ]

  # Assert package installs to correct location
  info "<YOUR TOOL LC> install -y <YOUR TOOL LC>json@1.2.8"
  get_lock git
  <YOUR TOOL LC> install -y <YOUR TOOL LC>json@1.2.8
  clear_lock git
  assert [ -x "./<YOUR TOOL LC>deps/bin/<YOUR TOOL LC>json" ]
  assert [ -f "./<YOUR TOOL LC>deps/pkgs/<YOUR TOOL LC>json-1.2.8/<YOUR TOOL LC>json.<YOUR TOOL LC>" ]
  assert [ ! -x "${ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH}/<YOUR TOOL LC>/bin/<YOUR TOOL LC>json" ]
  assert [ ! -f "${ASDF_<YOUR TOOL UC>_VERSION_INSTALL_PATH}/<YOUR TOOL LC>/pkgs/<YOUR TOOL LC>json-1.2.8/<YOUR TOOL LC>json.<YOUR TOOL LC>" ]

  # Assert that <YOUR TOOL LC> finds <YOUR TOOL LC> packages
  echo "import <YOUR TOOL LC>json" >"${ASDF_<YOUR TOOL UC>_TEST_TEMP}/test<YOUR TOOL LC>.<YOUR TOOL LC>"
  info "<YOUR TOOL LC> c --<YOUR TOOL LC>Path:./<YOUR TOOL LC>deps/pkgs -r \"${ASDF_<YOUR TOOL UC>_TEST_TEMP}/test<YOUR TOOL LC>.<YOUR TOOL LC>\""
  <YOUR TOOL LC> c --<YOUR TOOL LC>Path:./<YOUR TOOL LC>deps/pkgs -r "${ASDF_<YOUR TOOL UC>_TEST_TEMP}/test<YOUR TOOL LC>.<YOUR TOOL LC>"

  rm -rf <YOUR TOOL LC>deps
}
