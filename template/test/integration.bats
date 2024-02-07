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

	ASDF_DIR="$(mktemp -t asdf-<YOUR TOOL LC>-integration-tests.XXXX -d)"
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
	ASDF_<YOUR TOOL EUC>_TEST_TEMP="$(mktemp -t asdf-<YOUR TOOL LC>-integration-tests.XXXX -d)"
	export ASDF_<YOUR TOOL EUC>_TEST_TEMP
	ASDF_DATA_DIR="${ASDF_<YOUR TOOL EUC>_TEST_TEMP}/asdf"
	export ASDF_DATA_DIR
	mkdir -p "$ASDF_DATA_DIR/plugins"

	# `asdf plugin add asdf-<YOUR TOOL LC> .` would only install from git HEAD.
	# So, we install by copying the plugin to the plugins directory.
	cp -R "$PROJECT_DIR" "${ASDF_DATA_DIR}/plugins/asdf-<YOUR TOOL LC>"
	cd "${ASDF_DATA_DIR}/plugins/asdf-<YOUR TOOL LC>"

	# shellcheck disable=SC1090,SC1091
	source "${ASDF_DIR}/asdf.sh"

	ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH="${ASDF_DATA_DIR}/installs/asdf-<YOUR TOOL LC>/ref-version-1-6"
	export ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH

	# optimization if already installed
	info "asdf install asdf-<YOUR TOOL LC> ref:version-1-6"
	if [ -d "${HOME}/.asdf/installs/asdf-<YOUR TOOL LC>/ref-version-1-6" ]; then
		mkdir -p "${ASDF_DATA_DIR}/installs/asdf-<YOUR TOOL LC>"
		cp -R "${HOME}/.asdf/installs/asdf-<YOUR TOOL LC>/ref-version-1-6" "${ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH}"
		rm -rf "${ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH}/asdf-<YOUR TOOL LC>"
		asdf reshim
	else
		get_lock git
		asdf install asdf-<YOUR TOOL LC> ref:version-1-6
		clear_lock git
	fi
	asdf local asdf-<YOUR TOOL LC> ref:version-1-6
}

teardown() {
	asdf plugin remove asdf-<YOUR TOOL LC> || true
	rm -rf "${ASDF_<YOUR TOOL EUC>_TEST_TEMP}"
}

info() {
	echo "# ${*} …" >&3
}

@test "asdf-<YOUR TOOL LC>_configuration__without_asdf-<YOUR TOOL LC>deps" {
	# Assert package index is placed in the correct location
	info "asdf-<YOUR TOOL LC> refresh -y"
	get_lock git
	asdf-<YOUR TOOL LC> refresh -y
	clear_lock git
	assert [ -f "${ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH}/asdf-<YOUR TOOL LC>/packages_official.json" ]

	# Assert package installs to correct location
	info "asdf-<YOUR TOOL LC> install -y asdf-<YOUR TOOL LC>json@1.2.8"
	get_lock git
	asdf-<YOUR TOOL LC> install -y asdf-<YOUR TOOL LC>json@1.2.8
	clear_lock git
	assert [ -x "${ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH}/asdf-<YOUR TOOL LC>/bin/asdf-<YOUR TOOL LC>json" ]
	assert [ -f "${ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH}/asdf-<YOUR TOOL LC>/pkgs/asdf-<YOUR TOOL LC>json-1.2.8/asdf-<YOUR TOOL LC>json.asdf-<YOUR TOOL LC>" ]
	assert [ ! -x "./asdf-<YOUR TOOL LC>deps/bin/asdf-<YOUR TOOL LC>json" ]
	assert [ ! -f "./asdf-<YOUR TOOL LC>deps/pkgs/asdf-<YOUR TOOL LC>json-1.2.8/asdf-<YOUR TOOL LC>json.asdf-<YOUR TOOL LC>" ]

	# Assert that shim was created for package binary
	assert [ -f "${ASDF_DATA_DIR}/shims/asdf-<YOUR TOOL LC>json" ]

	# Assert that correct asdf-<YOUR TOOL LC>json is used
	assert [ -n "$(asdf-<YOUR TOOL LC>json -v | grep ' version 1\.2\.8')" ]

	# Assert that asdf-<YOUR TOOL LC> finds asdf-<YOUR TOOL LC> packages
	echo "import asdf-<YOUR TOOL LC>json" >"${ASDF_<YOUR TOOL EUC>_TEST_TEMP}/testasdf-<YOUR TOOL LC>.asdf-<YOUR TOOL LC>"
	info "asdf-<YOUR TOOL LC> c -r \"${ASDF_<YOUR TOOL EUC>_TEST_TEMP}/testasdf-<YOUR TOOL LC>.asdf-<YOUR TOOL LC>\""
	asdf-<YOUR TOOL LC> c -r "${ASDF_<YOUR TOOL EUC>_TEST_TEMP}/testasdf-<YOUR TOOL LC>.asdf-<YOUR TOOL LC>"
}

@test "asdf-<YOUR TOOL LC>_configuration__with_asdf-<YOUR TOOL LC>deps" {
	rm -rf asdf-<YOUR TOOL LC>deps
	mkdir "./asdf-<YOUR TOOL LC>deps"

	# Assert package index is placed in the correct location
	info "asdf-<YOUR TOOL LC> refresh"
	get_lock git
	asdf-<YOUR TOOL LC> refresh -y
	clear_lock git
	assert [ -f "./asdf-<YOUR TOOL LC>deps/packages_official.json" ]

	# Assert package installs to correct location
	info "asdf-<YOUR TOOL LC> install -y asdf-<YOUR TOOL LC>json@1.2.8"
	get_lock git
	asdf-<YOUR TOOL LC> install -y asdf-<YOUR TOOL LC>json@1.2.8
	clear_lock git
	assert [ -x "./asdf-<YOUR TOOL LC>deps/bin/asdf-<YOUR TOOL LC>json" ]
	assert [ -f "./asdf-<YOUR TOOL LC>deps/pkgs/asdf-<YOUR TOOL LC>json-1.2.8/asdf-<YOUR TOOL LC>json.asdf-<YOUR TOOL LC>" ]
	assert [ ! -x "${ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH}/asdf-<YOUR TOOL LC>/bin/asdf-<YOUR TOOL LC>json" ]
	assert [ ! -f "${ASDF_<YOUR TOOL EUC>_VERSION_INSTALL_PATH}/asdf-<YOUR TOOL LC>/pkgs/asdf-<YOUR TOOL LC>json-1.2.8/asdf-<YOUR TOOL LC>json.asdf-<YOUR TOOL LC>" ]

	# Assert that asdf-<YOUR TOOL LC> finds asdf-<YOUR TOOL LC> packages
	echo "import asdf-<YOUR TOOL LC>json" >"${ASDF_<YOUR TOOL EUC>_TEST_TEMP}/testasdf-<YOUR TOOL LC>.asdf-<YOUR TOOL LC>"
	info "asdf-<YOUR TOOL LC> c --asdf-<YOUR TOOL LC>Path:./asdf-<YOUR TOOL LC>deps/pkgs -r \"${ASDF_<YOUR TOOL EUC>_TEST_TEMP}/testasdf-<YOUR TOOL LC>.asdf-<YOUR TOOL LC>\""
	asdf-<YOUR TOOL LC> c --asdf-<YOUR TOOL LC>Path:./asdf-<YOUR TOOL LC>deps/pkgs -r "${ASDF_<YOUR TOOL EUC>_TEST_TEMP}/testasdf-<YOUR TOOL LC>.asdf-<YOUR TOOL LC>"

	rm -rf asdf-<YOUR TOOL LC>deps
}
