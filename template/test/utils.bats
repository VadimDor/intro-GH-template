#!/usr/bin/env bats

# shellcheck disable=SC2030,SC2031,SC2034,SC2230,SC2190

load ../node_modules/bats-support/load.bash
load ../node_modules/bats-assert/load.bash
load ../lib/utils
load ./lib/test_utils

setup_file() {
  PROJECT_DIR="$(realpath "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_DIR
  cd "$PROJECT_DIR"
  clear_lock git
}

teardown_file() {
  clear_lock git
}

setup() {
  setup_test
}

teardown() {
  teardown_test
}

# TODO: check tests below you really adopt

@test "<YOUR TOOL ELC>_log__install" {
  <YOUR TOOL ELC>_init "install"
  assert [ "$(<YOUR TOOL ELC>_log)" = "${ASDF_DATA_DIR}/tmp/<YOUR TOOL LC>/1.6.0/install.log" ]
}

@test "<YOUR TOOL ELC>_log__download" {
  <YOUR TOOL ELC>_init "download"
  assert [ "$(<YOUR TOOL ELC>_log)" = "${ASDF_DATA_DIR}/tmp/<YOUR TOOL LC>/1.6.0/download.log" ]
}

@test "<YOUR TOOL ELC>_init__defaults" {
  unset <YOUR TOOL EUC>_SILENT
  <YOUR TOOL ELC>_init "download"

  # Configurable
  assert_equal "$<YOUR TOOL EUC>_ACTION" "download"
  assert_equal "$<YOUR TOOL EUC>_REMOVE_TEMP" "yes"
  assert_equal "$<YOUR TOOL EUC>_DEBUG" "no"
  assert_equal "$<YOUR TOOL EUC>_SILENT" "no"

  # Non-configurable
  assert_equal "$<YOUR TOOL EUC>_TEMP" "${ASDF_DATA_DIR}/tmp/<YOUR TOOL LC>/1.6.0"
  assert_equal "$<YOUR TOOL EUC>_DOWNLOAD_PATH" "${<YOUR TOOL EUC>_TEMP}/download"
  assert_equal "$<YOUR TOOL EUC>_INSTALL_PATH" "${<YOUR TOOL EUC>_TEMP}/install"
}

@test "<YOUR TOOL ELC>_init__configuration" {
  <YOUR TOOL EUC>_REMOVE_TEMP="no"
  <YOUR TOOL EUC>_DEBUG="yes"
  <YOUR TOOL EUC>_SILENT="yes"
  <YOUR TOOL EUC>_TEMP="${<YOUR TOOL EUC>_TEST_TEMP}/configured"

  <YOUR TOOL ELC>_init "install"

  # Configurable
  assert_equal "$<YOUR TOOL EUC>_ACTION" "install"
  assert_equal "$<YOUR TOOL EUC>_REMOVE_TEMP" "no"
  assert_equal "$<YOUR TOOL EUC>_DEBUG" "yes"
  assert_equal "$<YOUR TOOL EUC>_SILENT" "yes"

  # Non-configurable
  assert_equal "$<YOUR TOOL EUC>_TEMP" "${ASDF_DATA_DIR}/tmp/<YOUR TOOL LC>/1.6.0"
  assert_equal "$<YOUR TOOL EUC>_DOWNLOAD_PATH" "${<YOUR TOOL EUC>_TEMP}/download"
  assert_equal "$<YOUR TOOL EUC>_INSTALL_PATH" "${<YOUR TOOL EUC>_TEMP}/install"
}

@test "<YOUR TOOL ELC>_cleanup" {
  original="$<YOUR TOOL EUC>_TEMP"
  run <YOUR TOOL ELC>_init &&
    <YOUR TOOL ELC>_cleanup &&
    [ -z "$<YOUR TOOL EUC>_TEMP" ] &&
    [ ! -d "$original" ] &&
    [ "$<YOUR TOOL EUC>_INITIALIZED" = "no" ]
  assert_success
  # TODO <YOUR TOOL EUC>_STDOUT/<YOUR TOOL EUC>_STDERR redirection test
}

@test "<YOUR TOOL ELC>_sort_versions" {
  expected="0.2.2 1.1.1 1.2.0 1.6.0"
  output="$(printf "1.6.0\n0.2.2\n1.1.1\n1.2.0" | <YOUR TOOL ELC>_sort_versions | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_list_all_versions__contains_tagged_releases" {
  run <YOUR TOOL ELC>_list_all_versions

  # Can't hardcode the ever-growing list of releases, so just check for a few known ones
  assert_line 0.10.2
  assert_line 1.4.0
  assert_line 1.6.0
}

@test "<YOUR TOOL ELC>_list_all_versions__displays_in_order" {
  assert [ "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.0' | sed 's/:.*//')" -gt "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.4.8' | sed 's/:.*//')" ]
  assert [ "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.2' | sed 's/:.*//')" -gt "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.0' | sed 's/:.*//')" ]
  assert [ "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.4' | sed 's/:.*//')" -gt "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.2' | sed 's/:.*//')" ]
  assert [ "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.6' | sed 's/:.*//')" -gt "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.4' | sed 's/:.*//')" ]
  assert [ "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.8' | sed 's/:.*//')" -gt "$(<YOUR TOOL ELC>_list_all_versions | grep -Fn '1.6.6' | sed 's/:.*//')" ]
}

@test "<YOUR TOOL ELC>_normalize_os" {
  mkdir -p "${<YOUR TOOL EUC>_TEST_TEMP}/bin"
  declare -A uname_outputs=(
    ["Darwin"]="macos"
    ["Linux"]="linux"
    ["MINGW"]="windows" # not actually supported by asdf?
    ["Unknown"]="unknown"
  )
  for uname_output in "${!uname_outputs[@]}"; do
    # mock uname
    <YOUR TOOL EUC>_MOCK_OS_NAME="${uname_output}"
    expected_os="${uname_outputs[$uname_output]}"
    output="$(<YOUR TOOL ELC>_normalize_os)"
    assert_equal "$output" "$expected_os"
  done
}

@test "<YOUR TOOL ELC>_normalize_arch__basic" {
  declare -A machine_names=(
    ["i386"]="i686"
    ["i486"]="i686"
    ["i586"]="i686"
    ["i686"]="i686"
    ["x86"]="i686"
    ["x32"]="i686"

    ["ppc64le"]="powerpc64le"
    ["unknown"]="unknown"
  )

  for machine_name in "${!machine_name[@]}"; do
    # mock uname
    <YOUR TOOL EUC>_MOCK_MACHINE_NAME="$machine_name"
    expected_arch="${machine_names[$machine_name]}"
    output="$(<YOUR TOOL ELC>_normalize_arch)"
    assert_equal "$output" "$expected_arch"
  done
}

@test "<YOUR TOOL ELC>_normalize_arch__i686__x86_64_docker" {
  # In x86_64 docker hosts running x86 containers,
  # the kernel uname will show x86_64 so we have to properly detect using the
  # __amd64 gcc define.

  # Expect i686 when __amd64 is not defined
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  expected_arch="i686"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"

  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="amd64"
  expected_arch="i686"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"

  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x64"
  expected_arch="i686"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"

  # Expect x86_64 only when __amd64 is defined
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"

  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  expected_arch="x86_64"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"

  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="amd64"
  expected_arch="x86_64"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"

  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x64"
  expected_arch="x86_64"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"
}

@test "<YOUR TOOL ELC>_normalize_arch__arm32__via_gcc" {
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="arm"
  for arm_version in {5..7}; do
    <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __ARM_ARCH ${arm_version}"
    expected_arch="armv${arm_version}"
    output="$(<YOUR TOOL ELC>_normalize_arch)"
    assert_equal "$output" "$expected_arch"
  done
}

@test "<YOUR TOOL ELC>_normalize_arch__armel__via_dpkg" {
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="arm"
  <YOUR TOOL EUC>_MOCK_DPKG_ARCHITECTURE="armel"
  expected_arch="armv5"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"
}

@test "<YOUR TOOL ELC>_normalize_arch__armhf__via_dpkg" {
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="arm"
  <YOUR TOOL EUC>_MOCK_DPKG_ARCHITECTURE="armhf"
  expected_arch="armv7"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"
}

@test "<YOUR TOOL ELC>_normalize_arch__arm__no_dpkg_no_gcc" {
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="arm"
  expected_arch="armv5"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"
}

@test "<YOUR TOOL ELC>_normalize_arch__armv7l__no_dpkg_no_gcc" {
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="armv7l"
  expected_arch="armv7"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"
}

@test "<YOUR TOOL ELC>_normalize_arch__arm64" {
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="arm64"
  <YOUR TOOL EUC>_MOCK_OS_NAME="Darwin"
  expected_arch="arm64"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"

  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  expected_arch="aarch64"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"

  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="aarch64"
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  expected_arch="aarch64"
  output="$(<YOUR TOOL ELC>_normalize_arch)"
  assert_equal "$output" "$expected_arch"
}

@test "<YOUR TOOL ELC>_pkg_mgr" {
  mkdir -p "${<YOUR TOOL EUC>_TEST_TEMP}/bin"
  declare -a bin_names=(
    "brew"
    "apt-get"
    "apk"
    "pacman"
    "dnf"
  )
  for bin_name in "${bin_names[@]}"; do
    # mock package manager
    touch "${<YOUR TOOL EUC>_TEST_TEMP}/bin/${bin_name}"
    chmod +x "${<YOUR TOOL EUC>_TEST_TEMP}/bin/${bin_name}"
    output="$(PATH="${<YOUR TOOL EUC>_TEST_TEMP}/bin" <YOUR TOOL ELC>_pkg_mgr)"
    rm "${<YOUR TOOL EUC>_TEST_TEMP}/bin/${bin_name}"
    assert_equal "$output" "$bin_name"
  done
}

@test "<YOUR TOOL ELC>_list_deps__apt_get" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="apt-get"
  expected="xz-utils build-essential"
  output="$(<YOUR TOOL ELC>_list_deps | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_list_deps__apk" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="apk"
  expected="xz build-base"
  output="$(<YOUR TOOL ELC>_list_deps | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_list_deps__brew" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="brew"
  expected="xz"
  output="$(<YOUR TOOL ELC>_list_deps | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_list_deps__pacman" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="pacman"
  expected="xz gcc"
  output="$(<YOUR TOOL ELC>_list_deps | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_list_deps__dnf" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="dnf"
  expected="xz gcc"
  output="$(<YOUR TOOL ELC>_list_deps | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_install_deps_cmds__apt_get" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="apt-get"
  expected="apt-get update -q -y && apt-get -qq install -y xz-utils build-essential"
  output="$(<YOUR TOOL ELC>_install_deps_cmds)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_install_deps_cmds__apk" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="apk"
  expected="apk add --update xz build-base"
  output="$(<YOUR TOOL ELC>_install_deps_cmds)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_install_deps_cmds__brew" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="brew"
  expected="brew install xz"
  output="$(<YOUR TOOL ELC>_install_deps_cmds)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_install_deps_cmds__pacman" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="pacman"
  expected="pacman -Syu --noconfirm xz gcc"
  output="$(<YOUR TOOL ELC>_install_deps_cmds)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_install_deps_cmds__dnf" {
  <YOUR TOOL EUC>_MOCK_PKG_MGR="dnf"
  expected="dnf install -y xz gcc"
  output="$(<YOUR TOOL ELC>_install_deps_cmds)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__stable__linux__x86_64__glibc" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="no"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"
  <YOUR TOOL ELC>_init "install"
  expected="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0-linux_x64.tar.xz https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__stable__linux__i686__glibc" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="no"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="i686"
  <YOUR TOOL ELC>_init "install"
  expected="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0-linux_x32.tar.xz https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__stable__linux__other_archs__glibc" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="no"
  declare -a machine_names=(
    "aarch64"
    "armv5"
    "armv6"
    "armv7"
    "powerpc64le"
  )
  for machine_name in "${machine_names[@]}"; do
    <YOUR TOOL EUC>_MOCK_MACHINE_NAME="$machine_name"
    <YOUR TOOL ELC>_init "install"
    expected="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0.tar.xz"
    output="$(<YOUR TOOL ELC>_download_urls | xargs)"
    assert_equal "$output" "$expected"
  done
}

@test "<YOUR TOOL ELC>_download_urls__stable__linux__x86_64__musl" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="yes"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"
  <YOUR TOOL ELC>_init "install"
  expected="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__stable__linux__other_archs__musl" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="yes"
  declare -a machine_names=(
    "aarch64"
    "armv5"
    "armv6"
    "armv7"
    "i686"
    "powerpc64le"
  )
  for machine_name in "${machine_names[@]}"; do
    <YOUR TOOL EUC>_MOCK_MACHINE_NAME="$machine_name"
    <YOUR TOOL ELC>_init "install"
    expected="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0.tar.xz"
    output="$(<YOUR TOOL ELC>_download_urls | xargs)"
    assert_equal "$output" "$expected"
  done
}

@test "<YOUR TOOL ELC>_download_urls__stable__macos__x86_64" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Darwin"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"
  <YOUR TOOL ELC>_init "install"
  expected="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__stable__macos__arm64" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Darwin"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="arm64"
  <YOUR TOOL ELC>_init "install"
  expected="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__stable__netbsd__x86_64" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="NetBSD"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"
  <YOUR TOOL ELC>_init "install"
  expected="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-1.6.0.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__nightly__linux__x86_64__musl" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="yes"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  <YOUR TOOL ELC>_init "install"
  expected=""
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__nightly__linux__other_archs__musl" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="yes"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  declare -a machine_names=(
    "aarch64"
    "armv5"
    "armv6"
    "armv7"
    "i686"
    "powerpc64le"
  )
  for machine_name in "${machine_names[@]}"; do
    <YOUR TOOL EUC>_MOCK_MACHINE_NAME="$machine_name"
    <YOUR TOOL ELC>_init "install"
    expected=""
    output="$(<YOUR TOOL ELC>_download_urls | xargs)"
    assert_equal "$output" "$expected"
  done
}

@test "<YOUR TOOL ELC>_download_urls__nightly__linux__x86_64__glibc" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="no"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  <YOUR TOOL ELC>_init "install"
  expected="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-version-1-6/linux_x64.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__nightly__linux__i686__glibc" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="no"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="i686"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  <YOUR TOOL ELC>_init "install"
  expected="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-version-1-6/linux_x32.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__nightly__linux__other_archs__glibc" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_IS_MUSL="no"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  declare -a machine_names=(
    "armv5"
    "armv6"
    "powerpc64le"
  )
  for machine_name in "${machine_names[@]}"; do
    <YOUR TOOL EUC>_MOCK_MACHINE_NAME="$machine_name"
    <YOUR TOOL ELC>_init "install"
    expected=""
    output="$(<YOUR TOOL ELC>_download_urls | xargs)"
    assert_equal "$output" "$expected"
  done
}

@test "<YOUR TOOL ELC>_download_urls__nightly__linux__armv7__glibc" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="armv7"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  <YOUR TOOL ELC>_init "install"
  expected="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-version-1-6/linux_armv7l.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__nightly__linux__aarch64__glibc" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Linux"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="aarch64"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="devel"
  <YOUR TOOL ELC>_init "install"
  expected="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-devel/linux_arm64.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__nightly__macos__x86_64" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Darwin"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  <YOUR TOOL ELC>_init "install"
  expected="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-version-1-6/macosx_x64.tar.xz"
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__nightly__macos__arm64" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="Darwin"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="arm64"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  <YOUR TOOL ELC>_init "install"
  expected=""
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_download_urls__nightly__netbsd__x86_64" {
  <YOUR TOOL EUC>_MOCK_OS_NAME="NetBSD"
  <YOUR TOOL EUC>_MOCK_MACHINE_NAME="x86_64"
  <YOUR TOOL EUC>_MOCK_GCC_DEFINES="#define __amd64 1"
  ASDF_INSTALL_TYPE="ref"
  ASDF_INSTALL_VERSION="version-1-6"
  <YOUR TOOL ELC>_init "install"
  expected=""
  output="$(<YOUR TOOL ELC>_download_urls | xargs)"
  assert_equal "$output" "$expected"
}

@test "<YOUR TOOL ELC>_needs_download__missing_ASDF_DOWNLOAD_PATH" {
  <YOUR TOOL ELC>_init "install"
  run <YOUR TOOL ELC>_needs_download
  assert_output "yes"
}

@test "<YOUR TOOL ELC>_needs_download__with_ASDF_DOWNLOAD_PATH" {
  <YOUR TOOL ELC>_init "install"
  mkdir -p "$ASDF_DOWNLOAD_PATH"
  run <YOUR TOOL ELC>_needs_download
  assert_output "no"
}

@test "<YOUR TOOL ELC>_download__ref" {
  export ASDF_INSTALL_TYPE
  ASDF_INSTALL_TYPE="ref"
  export ASDF_INSTALL_VERSION
  ASDF_INSTALL_VERSION="HEAD"
  <YOUR TOOL ELC>_init "download"
  get_lock git
  run <YOUR TOOL ELC>_download
  clear_lock git
  assert_success
  assert [ -d "${ASDF_DOWNLOAD_PATH}/.git" ]
  assert [ -f "${ASDF_DOWNLOAD_PATH}/koch.<YOUR TOOL LC>" ]
}

@test "<YOUR TOOL ELC>_download__version" {
  ASDF_DOWNLOAD_PATH="${ASDF_DATA_DIR}/downloads/<YOUR TOOL LC>/${ASDF_INSTALL_VERSION}"
  <YOUR TOOL ELC>_init "download"
  get_lock git
  run <YOUR TOOL ELC>_download
  clear_lock git
  assert_success
  refute [ -d "${ASDF_DOWNLOAD_PATH}/.git" ]
  assert [ -f "${ASDF_DOWNLOAD_PATH}/koch.<YOUR TOOL LC>" ]
}

# @test "<YOUR TOOL ELC>_build" {
#   skip "TODO, but covered by integration tests & CI"
# }

# @test "<YOUR TOOL ELC>_install" {
#   skip "TODO, but covered by integration tests & CI"
# }
