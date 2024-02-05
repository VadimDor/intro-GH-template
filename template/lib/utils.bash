#!/usr/bin/env bash

# shellcheck disable=SC2230

# Constants
SOURCE_REPO="https://github.com/<YOUR TOOL LC>-lang/<YOUR TOOL ULC>.git"
SOURCE_URL="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-VERSION.tar.xz"

LINUX_X64_NIGHTLY_URL="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-BRANCH/linux_x64.tar.xz"
LINUX_X32_NIGHTLY_URL="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-BRANCH/linux_x32.tar.xz"
LINUX_ARM64_NIGHTLY_URL="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-BRANCH/linux_arm64.tar.xz"
LINUX_ARMV7L_NIGHTLY_URL="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-BRANCH/linux_armv7l.tar.xz"
MACOS_X64_NIGHTLY_URL="https://github.com/<YOUR TOOL LC>-lang/nightlies/releases/download/latest-BRANCH/macosx_x64.tar.xz"

LINUX_X64_URL="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-VERSION-linux_x64.tar.xz"
LINUX_X32_URL="https://<YOUR TOOL LC>-lang.org/download/<YOUR TOOL LC>-VERSION-linux_x32.tar.xz"
# see https://github.com/asdf-community/asdf-nim/blob/main/lib/utils.bash
<YOUR TOOL UC>_ARGS=("--parallelBuild:${ASDF_CONCURRENCY:-0}" "-d:release") # Args to pass to koch/<YOUR TOOL LC>

normpath() {
  # Remove all /./ sequences.
  local path
  path="${1//\/.\//\/}"
  # Remove dir/.. sequences.
  while [[ $path =~ ([^/][^/]*/\.\./?) ]]; do
    path="${path/${BASH_REMATCH[0]}/}"
  done
  echo "$path" | sed 's/\/$//'
}

# Create the temp directories used by the download/build/install functions.
<YOUR TOOL ELC>_init() {
  export <YOUR TOOL EUC>_ACTION
  <YOUR TOOL EUC>_ACTION="$1"

  # Configuration options
  export <YOUR TOOL EUC>_REMOVE_TEMP
  <YOUR TOOL EUC>_REMOVE_TEMP="${<YOUR TOOL EUC>_REMOVE_TEMP:-yes}" # If no, <YOUR TOOL LC>'s temporary directory won't be deleted on exit
  export <YOUR TOOL EUC>_DEBUG
  <YOUR TOOL EUC>_DEBUG="${<YOUR TOOL EUC>_DEBUG:-no}" # If yes, extra information will be logged to the console and every command executed will be logged to the logfile.
  export <YOUR TOOL EUC>_STDOUT
  <YOUR TOOL EUC>_STDOUT="${<YOUR TOOL EUC>_STDOUT:-1}" # The file descriptor where the script's standard output should be directed.
  export <YOUR TOOL EUC>_STDERR
  <YOUR TOOL EUC>_STDERR="${<YOUR TOOL EUC>_STDERR:-2}" # The file descriptor where the script's standard error output should be directed.
  export <YOUR TOOL EUC>_SILENT
  <YOUR TOOL EUC>_SILENT="${<YOUR TOOL EUC>_SILENT:-no}" # If yes, <YOUR TOOL LC> will not echo build steps to stdout.
  # End configuration options

  # Ensure ASDF_DATA_DIR has a value
  if [ -n "${ASDF_INSTALL_PATH-}" ]; then
    export ASDF_DATA_DIR
    ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
    export <YOUR TOOL EUC>_TEMP
    <YOUR TOOL EUC>_TEMP="${ASDF_DATA_DIR}/tmp/<YOUR TOOL LC>/${ASDF_INSTALL_VERSION}"
    export <YOUR TOOL EUC>_DOWNLOAD_PATH
    <YOUR TOOL EUC>_DOWNLOAD_PATH="${<YOUR TOOL EUC>_TEMP}/download" # Temporary directory where downloads are placed
    export <YOUR TOOL EUC>_INSTALL_PATH
    <YOUR TOOL EUC>_INSTALL_PATH="${<YOUR TOOL EUC>_TEMP}/install" # Temporary directory where installation is prepared
    mkdir -p "$<YOUR TOOL EUC>_TEMP"
    rm -f "$(<YOUR TOOL ELC>_log)"
  fi

  if [ "$<YOUR TOOL EUC>_DEBUG" = "yes" ]; then
    out
    out "# Environment:"
    out
    env | grep "^ASDF_" | sort | xargs printf "#  %s\n" 1>&"$<YOUR TOOL EUC>_STDOUT" 2>&"$<YOUR TOOL EUC>_STDERR" || true
  fi
}

<YOUR TOOL ELC>_init_traps() {
  # Exit handlers
  trap '<YOUR TOOL EUC>_EXIT_STATUS=$?; <YOUR TOOL ELC>_on_exit; exit $<YOUR TOOL EUC>_EXIT_STATUS' EXIT
  trap 'trap - HUP; <YOUR TOOL EUC>_SIGNAL=SIGHUP; kill -HUP $$' HUP
  trap 'trap - INT; <YOUR TOOL EUC>_SIGNAL=SIGINT; kill -INT $$' INT
  trap 'trap - TERM; <YOUR TOOL EUC>_SIGNAL=SIGTERM; kill -TERM $$' TERM
}

out() {
  # To screen
  if [ "$<YOUR TOOL EUC>_SILENT" = "no" ]; then
    echo "$@" 1>&"$<YOUR TOOL EUC>_STDOUT" 2>&"$<YOUR TOOL EUC>_STDERR"
  fi
}

<YOUR TOOL ELC>_on_exit() {
  <YOUR TOOL ELC>_cleanup_asdf_install_path() {
    if [ -d "$ASDF_INSTALL_PATH" ]; then
      step_start "rm ${ASDF_INSTALL_PATH//${HOME}/\~} …"
      rm -rf "$ASDF_INSTALL_PATH"
      step_end "✓"
    fi
  }

  <YOUR TOOL ELC>_cleanup_asdf_download_path() {
    if [ -d "$ASDF_DOWNLOAD_PATH" ]; then
      if [ "${1-}" = "force" ]; then
        # Force delete
        step_start "rm ${ASDF_DOWNLOAD_PATH//${HOME}/\~}"
        rm -rf "$ASDF_DOWNLOAD_PATH"
        step_end "✓"
      else
        # asdf will delete this folder depending on --keep-download or
        # always_keep_download flag, so respect that by not deleting here;
        # however, asdf uses `rm -r` instead of `rm -rf` which fails to delete
        # protected git objects. So we simply chmod the git objects so they
        # can be deleted if asdf decides to delete.
        step_start "chmod ${ASDF_DOWNLOAD_PATH//${HOME}/\~}"
        chmod -R 700 "$ASDF_DOWNLOAD_PATH"
        step_end "✓"
      fi
    fi
  }

  <YOUR TOOL ELC>_cleanup_temp() {
    if [ -d "$<YOUR TOOL EUC>_TEMP" ]; then
      if [ "$<YOUR TOOL EUC>_REMOVE_TEMP" = "yes" ]; then
        step_start "rm ${<YOUR TOOL EUC>_TEMP//${HOME}/\~}"
        rm -rf "$<YOUR TOOL EUC>_TEMP"
        step_end "✓"
      else
        step_start "<YOUR TOOL EUC>_REMOVE_TEMP=${<YOUR TOOL EUC>_REMOVE_TEMP}, keeping temp dir ${<YOUR TOOL EUC>_TEMP//${HOME}/\~}"
        step_end "✓"
      fi
    fi
  }

  case "$<YOUR TOOL EUC>_ACTION" in
    download)
      # install gets called by asdf even after a failed download, so don't do
      # any cleanup here... *unless* <YOUR TOOL EUC>_SIGNAL is set, in which case
      # install will not be called and ASDF_DOWNLOAD_PATH should be deleted
      # regardless of --keep-download/always_keep_download.
      case "${<YOUR TOOL EUC>_SIGNAL-}" in
        SIG*)
          # cleanup everything
          <YOUR TOOL ELC>_cleanup_asdf_install_path
          <YOUR TOOL ELC>_cleanup_asdf_download_path force
          <YOUR TOOL ELC>_cleanup_temp
          out
          ;;
        *) ;;
      esac
      ;;
    install)
      # actually do cleanup here
      case "$<YOUR TOOL EUC>_EXIT_STATUS" in
        0)
          # successful install, only clean up temp dir, make download path
          # removable.
          <YOUR TOOL ELC>_cleanup_asdf_download_path
          <YOUR TOOL ELC>_cleanup_temp
          out
          ;;
        *)
          # failure, dump log
          out
          out "😱 Exited with status ${<YOUR TOOL EUC>_EXIT_STATUS}:"
          out
          cat "$(<YOUR TOOL ELC>_log download)" 1>&"$<YOUR TOOL EUC>_STDOUT" 2>&"$<YOUR TOOL EUC>_STDERR"
          cat "$(<YOUR TOOL ELC>_log install)" 1>&"$<YOUR TOOL EUC>_STDOUT" 2>&"$<YOUR TOOL EUC>_STDERR"
          # cleanup everything
          out
          <YOUR TOOL ELC>_cleanup_asdf_install_path
          <YOUR TOOL ELC>_cleanup_asdf_download_path
          <YOUR TOOL ELC>_cleanup_temp
          out
          ;;
      esac
      ;;
  esac
}

# Log file path. Most command output gets redirected here.
<YOUR TOOL ELC>_log() {
  local path
  path="${<YOUR TOOL EUC>_TEMP}/${1:-$<YOUR TOOL EUC>_ACTION}.log"
  touch "$path"
  echo "$path"
}

STEP=0

section_start() {
  STEP=0
  if [ "$<YOUR TOOL EUC>_SILENT" = "no" ]; then
    printf "\n%s\n" "$1" 1>&"$<YOUR TOOL EUC>_STDOUT" 2>&"$<YOUR TOOL EUC>_STDERR"
  fi
}

step_start() {
  export STEP=$((STEP + 1))
  if [ "$<YOUR TOOL EUC>_SILENT" = "no" ]; then
    printf "     %s. %s … " "$STEP" "$1" 1>&"$<YOUR TOOL EUC>_STDOUT" 2>&"$<YOUR TOOL EUC>_STDERR"
  fi
}

step_end() {
  if [ "$<YOUR TOOL EUC>_SILENT" = "no" ]; then
    printf "%s\n" "$1" 1>&"$<YOUR TOOL EUC>_STDOUT" 2>&"$<YOUR TOOL EUC>_STDERR"
  fi
}

die() {
  if [ "$<YOUR TOOL EUC>_SILENT" = "no" ]; then
    printf "\n💥 %s\n\n" "$1" 1>&"$<YOUR TOOL EUC>_STDERR"
  fi
}

# Sort semantic version numbers.
<YOUR TOOL ELC>_sort_versions() {
  awk '{ if ($1 ~ /-/) print; else print $0"_" ; }' | sort -V | sed 's/_$//'
}

# List all stable <YOUR TOOL ULC> versions (tagged releases at github.com/<YOUR TOOL LC>-lang/<YOUR TOOL ULC>).
<YOUR TOOL ELC>_list_all_versions() {
  git ls-remote --tags --refs "$SOURCE_REPO" |
    awk -v col=2 '{print $col}' |
    grep '^refs/tags/.*' |
    sed 's/^refs\/tags\///' |
    sed 's/^v//' |
    <YOUR TOOL ELC>_sort_versions
}

<YOUR TOOL ELC>_normalize_os() {
  local os
  os="$(echo "${<YOUR TOOL EUC>_MOCK_OS_NAME:-$(uname)}" | tr '[:upper:]' '[:lower:]')"
  case "$os" in
    darwin) echo macos ;;
    mingw*) echo windows ;; # not actually supported by asdf?
    *) echo "$os" ;;
  esac
}

# Detect the platform's architecture, normalize it to one of the following, and
# echo it:
# - x86_64
# - i686
# - armv5
# - armv6
# - armv7
# - aaarch64 (on Linux)
# - arm64 (on macOS)
# - powerpc64le
<YOUR TOOL ELC>_normalize_arch() {
  local arch arm_arch arch_version
  arch="${<YOUR TOOL EUC>_MOCK_MACHINE_NAME:-$(uname -m)}"
  case "$arch" in
    x86_64 | x64 | amd64)
      if [ -n "$(command -v gcc)" ] || [ -n "${<YOUR TOOL EUC>_MOCK_GCC_DEFINES-}" ]; then
        # Edge case: detect 386 container on amd64 kernel using __amd64 definition
        IS_AMD64="$(echo "${<YOUR TOOL EUC>_MOCK_GCC_DEFINES:-$(gcc -dM -E - </dev/null)}" | grep "#define __amd64 " | sed 's/#define __amd64 //')"
        if [ "$IS_AMD64" = "1" ]; then
          echo "x86_64"
        else
          echo "i686"
        fi
      else
        # No gcc, so can't detect 386 container on amd64 kernel. x86_64 is most likely case
        echo "x86_64"
      fi
      ;;
    *86* | x32) echo "i686" ;;
    *aarch64* | *arm64* | armv8b | armv8l)
      case "$(<YOUR TOOL ELC>_normalize_os)" in
        macos) echo arm64 ;;
        *) echo "aarch64" ;;
      esac
      ;;
    arm*)
      arm_arch=""
      if [ -n "$(command -v gcc)" ] || [ -n "${<YOUR TOOL EUC>_MOCK_GCC_DEFINES-}" ]; then
        # Detect arm32 version using __ARM_ARCH definition
        arch_version="$(echo "${<YOUR TOOL EUC>_MOCK_GCC_DEFINES:-$(gcc -dM -E - </dev/null)}" | grep "#define __ARM_ARCH " | sed 's/#define __ARM_ARCH //')"
        if [ -n "$arch_version" ]; then
          arm_arch="armv$arch_version"
        fi
      fi
      if [ -z "$arm_arch" ]; then
        if [ -n "$(command -v dpkg)" ] || [ -n "${<YOUR TOOL EUC>_MOCK_DPKG_ARCHITECTURE-}" ]; then
          # Detect arm32 version using dpkg
          case "${<YOUR TOOL EUC>_MOCK_DPKG_ARCHITECTURE:-"$(dpkg --print-architecture)"}" in
            armel) arm_arch="armv5" ;;
            armhf) arm_arch="armv7" ;;
          esac
        fi
      fi
      if [ -z "$arm_arch" ]; then
        if [ "$arch" = "arm" ]; then
          # If couldn't detect, go low
          arm_arch="armv5"
        else
          # Something like armv7l -> armv7
          # shellcheck disable=SC2001
          arm_arch="$(echo "$arch" | sed 's/^\(armv[0-9]\{1,\}\).*$/\1/')"
        fi
      fi
      echo "$arm_arch"
      ;;
    ppc64le | powerpc64le | ppc64el | powerpc64el) echo powerpc64le ;;
    *) echo "$arch" ;;
  esac
}

<YOUR TOOL ELC>_pkg_mgr() {
  echo "${<YOUR TOOL EUC>_MOCK_PKG_MGR:-$(
    (command -v brew >/dev/null 2>&1 && echo "brew") ||
      (command -v apt-get >/dev/null 2>&1 && echo "apt-get") ||
      (command -v apk >/dev/null 2>&1 && echo "apk") ||
      (command -v pacman >/dev/null 2>&1 && echo "pacman") ||
      (command -v dnf >/dev/null 2>&1 && echo "dnf") ||
      echo ""
  )}"
}

# List dependencies of this plugin, as package names for use with the system
# package manager.
<YOUR TOOL ELC>_list_deps() {
  case "$(<YOUR TOOL ELC>_pkg_mgr)" in
    apt-get)
      echo xz-utils
      echo build-essential
      ;;
    apk)
      echo xz
      echo build-base
      ;;
    brew) echo xz ;;
    *)
      case "$(<YOUR TOOL ELC>_normalize_os)" in
        *)
          echo xz
          echo gcc
          ;;
      esac
      ;;
  esac
}

# Generate the command to install dependencies via the system package manager.
<YOUR TOOL ELC>_install_deps_cmds() {
  local deps
  deps="$(<YOUR TOOL ELC>_list_deps | xargs)"
  case "$(<YOUR TOOL ELC>_pkg_mgr)" in
    apt-get) echo "apt-get update -q -y && apt-get -qq install -y $deps" ;;
    apk) echo "apk add --update $deps" ;;
    brew) echo "brew install $deps" ;;
    pacman) echo "pacman -Syu --noconfirm $deps" ;;
    dnf) echo "dnf install -y $deps" ;;
    *) echo "" ;;
  esac
}

# Install missing dependencies using the system package manager.
# Note - this is interactive, so in CI use `yes | cmd-that-calls-<YOUR TOOL ELC>_install_deps`.
<YOUR TOOL ELC>_install_deps() {
  local deps
  deps="$(<YOUR TOOL ELC>_list_deps | xargs)"
  local input
  input=""
  echo
  echo "[<YOUR TOOL LC>:install-deps] additional packages are required: ${deps}"
  echo
  if [ "${<YOUR TOOL EUC>_INSTALL_DEPS_ACCEPT:-no}" = "no" ]; then
    read -r -p "[<YOUR TOOL LC>:install-deps] Install them now? [Y/n] " input
  else
    echo "[<YOUR TOOL LC>:install-deps] --yes passed, installing…"
    input="yes"
  fi
  echo

  case "$input" in
    [yY][eE][sS] | [yY] | "")
      local cmds
      cmds="$(<YOUR TOOL ELC>_install_deps_cmds)"
      if [ -z "$cmds" ]; then
        echo
        echo "[<YOUR TOOL LC>:install-deps] no package managers recognized, install the packages manually."
        echo
        return 1
      else
        eval "$cmds"
        echo
        echo "[<YOUR TOOL LC>:install-deps] installed: ${deps}"
        echo
      fi
      ;;
    *)
      echo
      echo "[<YOUR TOOL LC>:install-deps] plugin will not function without: ${deps}"
      echo
      return 1
      ;;
  esac
  echo
}

# Detect if the standard C library on the system is musl or not.
# Echoes "yes" or "no"
<YOUR TOOL ELC>_is_musl() {
  if [ -n "${<YOUR TOOL EUC>_MOCK_IS_MUSL-}" ]; then
    echo "$<YOUR TOOL EUC>_MOCK_IS_MUSL"
  else
    if [ -n "$(command -v ldd)" ]; then
      if (ldd --version 2>&1 || true) | grep -qF "musl"; then
        echo "yes"
      else
        echo "no"
      fi
    else
      echo "no"
    fi
  fi
}

# Echo the official binary archive URL (from <YOUR TOOL LC>-lang.org) for the current
# architecture.
<YOUR TOOL ELC>_official_archive_url() {
  if [ "${ASDF_INSTALL_TYPE}" = "version" ] && [[ ${ASDF_INSTALL_VERSION} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    case "$(<YOUR TOOL ELC>_normalize_os)" in
      linux)
        case "$(<YOUR TOOL ELC>_is_musl)" in
          no)
            # Official Linux builds are only available for glibc x86_64 and x86
            case "$(<YOUR TOOL ELC>_normalize_arch)" in
              x86_64) echo "${LINUX_X64_URL//VERSION/$ASDF_INSTALL_VERSION}" ;;
              i686) echo "${LINUX_X32_URL//VERSION/$ASDF_INSTALL_VERSION}" ;;
            esac
            ;;
        esac
        ;;
    esac
  fi
}

# Echo the nightly url for arch/os
<YOUR TOOL ELC>_nightly_url() {
  if [ "${ASDF_INSTALL_TYPE}" != "ref" ]; then
    return 0
  fi
  if [[ $ASDF_INSTALL_VERSION =~ ^version-[0-9]+-[0-9]+$ ]] || [ "$ASDF_INSTALL_VERSION" = "devel" ]; then
    case "$(<YOUR TOOL ELC>_normalize_os)" in
      linux)
        case "$(<YOUR TOOL ELC>_is_musl)" in
          no)
            # Nightly Linux builds are only available for glibc and a few archs
            case "$(<YOUR TOOL ELC>_normalize_arch)" in
              x86_64) echo "${LINUX_X64_NIGHTLY_URL//BRANCH/$ASDF_INSTALL_VERSION}" ;;
              i686) echo "${LINUX_X32_NIGHTLY_URL//BRANCH/$ASDF_INSTALL_VERSION}" ;;
              aarch64) echo "${LINUX_ARM64_NIGHTLY_URL//BRANCH/$ASDF_INSTALL_VERSION}" ;;
              armv7) echo "${LINUX_ARMV7L_NIGHTLY_URL//BRANCH/$ASDF_INSTALL_VERSION}" ;;
            esac
            ;;
        esac
        ;;
      macos)
        case "$(<YOUR TOOL ELC>_normalize_arch)" in
          # Nightly macos builds are only available for x86_64
          x86_64) echo "${MACOS_X64_NIGHTLY_URL//BRANCH/$ASDF_INSTALL_VERSION}" ;;
        esac
        ;;
    esac
  fi
}

<YOUR TOOL ELC>_github_token() {
  echo "${GITHUB_TOKEN:-${GITHUB_API_TOKEN-}}"
}

# Echo the source archive URL (from <YOUR TOOL LC>-lang.org).
<YOUR TOOL ELC>_source_url() {
  if [ "${ASDF_INSTALL_TYPE}" = "version" ] && [[ ${ASDF_INSTALL_VERSION} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "${SOURCE_URL//VERSION/$ASDF_INSTALL_VERSION}"
  fi
}

<YOUR TOOL ELC>_needs_download() {
  # No download path
  if [ ! -d "$ASDF_DOWNLOAD_PATH" ]; then
    echo "yes"
  else
    echo "no"
  fi
}

<YOUR TOOL ELC>_download_urls() {
  # Official binaries
  <YOUR TOOL ELC>_official_archive_url
  # Nightly binaries
  <YOUR TOOL ELC>_nightly_url
  # Fall back to building from source
  <YOUR TOOL ELC>_source_url
}

<YOUR TOOL ELC>_download_via_git() {
  step_start "git clone"
  rm -rf "$<YOUR TOOL EUC>_DOWNLOAD_PATH"
  mkdir -p "$<YOUR TOOL EUC>_DOWNLOAD_PATH"
  (
    cd "$<YOUR TOOL EUC>_DOWNLOAD_PATH"
    git init
    git remote add origin "$SOURCE_REPO"
    git fetch origin "$ASDF_INSTALL_VERSION" --depth 1
    git reset --hard FETCH_HEAD
    chmod -R 700 . # For asdf cleanup
  )
  step_end "✓"
}

<YOUR TOOL ELC>_download_via_url() {
  local urls url archive_path archive_name archive_ext
  # shellcheck disable=SC2207
  urls=($(<YOUR TOOL ELC>_download_urls))
  url=""
  archive_path=""
  if [ "${#urls[@]}" -eq 0 ]; then
    return 1
  fi
  for i in "${!urls[@]}"; do
    url="${urls[$i]}"
    step_start "curl ${url}"
    archive_path="$(<YOUR TOOL ELC>_fetch "$url")"
    if [ -n "$archive_path" ]; then
      step_end "✓"
      break
    else
      if [ "$((i + 1))" -ge "${#urls[@]}" ]; then
        step_end "failed, no more URLs to try"
        return 1
      else
        step_end "failed, trying another URL"
      fi
    fi
  done
  archive_name="$(basename "$url")"
  archive_ext="${archive_name##*.}"
  step_start "unzip"

  rm -rf "$<YOUR TOOL EUC>_DOWNLOAD_PATH"
  mkdir -p "$<YOUR TOOL EUC>_DOWNLOAD_PATH"

  case "$archive_ext" in
    xz) tar -xJf "${<YOUR TOOL EUC>_TEMP}/${archive_name}" -C "$<YOUR TOOL EUC>_DOWNLOAD_PATH" --strip-components=1 ;;
    *)
      unzip -q "${<YOUR TOOL EUC>_TEMP}/${archive_name}" -d "$<YOUR TOOL EUC>_DOWNLOAD_PATH"
      mv -v "$<YOUR TOOL EUC>_DOWNLOAD_PATH/<YOUR TOOL LC>-${ASDF_INSTALL_VERSION}/"* "$<YOUR TOOL EUC>_DOWNLOAD_PATH"
      rm -vr "$<YOUR TOOL EUC>_DOWNLOAD_PATH/<YOUR TOOL LC>-${ASDF_INSTALL_VERSION}"
      ;;
  esac
  step_end "✓"
}

# Detect which method to install <YOUR TOOL ULC> with (official binary, nightly binary, or
# build from source), download the code to <YOUR TOOL EUC>_DOWNLOAD_PATH, prepare it for
# use by the build or install functions, then move it to ASDF_DOWNLOAD_PATH.
<YOUR TOOL ELC>_download() {
  section_start "I.   Download (${<YOUR TOOL EUC>_DOWNLOAD_PATH//${HOME}/\~})"
  {

    if [ -f "${ASDF_DOWNLOAD_PATH}/install.sh" ] || [ -f "${ASDF_DOWNLOAD_PATH}/build.sh" ] || [ -f "${ASDF_DOWNLOAD_PATH}/build_all.sh" ]; then
      step_start "already downloaded"
      step_end "✓"
      return 0
    fi

    date +%s >"${<YOUR TOOL EUC>_TEMP}/download.start"

    if [ "$<YOUR TOOL EUC>_DEBUG" = "yes" ]; then
      set -x
    fi

    # ref install type is usually a git commit-ish
    # but if it one of the "version-X-Y" branches,
    # it may have a nightly build for the current arch/os
    # so first try to download via URL
    # but if none is available, fallback to git
    if ! <YOUR TOOL ELC>_download_via_url; then
      if [ "${ASDF_INSTALL_TYPE}" = "ref" ]; then
        <YOUR TOOL ELC>_download_via_git
      else
        die "No download method available for ${ASDF_INSTALL_TYPE} ${ASDF_INSTALL_VERSION}"
        return 1
      fi
    fi

    step_start "mv to ${ASDF_DOWNLOAD_PATH//${HOME}/\~}"
    rm -rf "$ASDF_DOWNLOAD_PATH"
    mkdir -p "$(dirname "$ASDF_DOWNLOAD_PATH")"
    mv -v "$<YOUR TOOL EUC>_DOWNLOAD_PATH" "$ASDF_DOWNLOAD_PATH"
    step_end "✓"

    if [ "$<YOUR TOOL EUC>_DEBUG" = "yes" ]; then
      set +x
    fi
  } 1>>"$(<YOUR TOOL ELC>_log)" 2>>"$(<YOUR TOOL ELC>_log)"
}

<YOUR TOOL ELC>_fetch() {
  local url
  url="$1"
  declare -a curl_args
  curl_args=("-fsSL" "--connect-timeout" "10")

  # Use a github personal access token to avoid API rate limiting
  if [ -n "$(<YOUR TOOL ELC>_github_token)" ]; then
    case "$url" in
      'https://github.com/'*)
        curl_args+=("-H" "Authorization: token $(<YOUR TOOL ELC>_github_token)")
        ;;
    esac
  fi

  # Debian ARMv7 at least seem to have out-of-date ca certs, so use a newer
  # one from Mozilla.
  case "$(<YOUR TOOL ELC>_normalize_arch)" in
    armv*)
      curl_args+=("--cacert" "${ASDF_DATA_DIR}/plugins/<YOUR TOOL LC>/share/cacert.pem")
      ;;
  esac
  local archive_name
  archive_name="$(basename "$url")"
  local archive_path
  archive_path="${<YOUR TOOL EUC>_TEMP}/${archive_name}"

  curl_args+=("$url" "-o" "$archive_path")

  # shellcheck disable=SC2046
  eval curl $(printf ' "%s" ' "${curl_args[@]}") && echo "$archive_path" || echo ""
}

<YOUR TOOL ELC>_bootstrap_<YOUR TOOL LC>() {
  cd "$ASDF_DOWNLOAD_PATH"

  local <YOUR TOOL LC>
  <YOUR TOOL LC>="./bin/<YOUR TOOL LC>"
  if [ ! -f "$<YOUR TOOL LC>" ]; then
    if [ -f "build.sh" ]; then
      # source directory has build.sh to build koch, <YOUR TOOL LC>, and tools.
      step_start "./build.sh"
      sh build.sh
      step_end "✓"
    elif [ -f "build_all.sh" ]; then
      # source directory has build_all.sh to build koch, <YOUR TOOL LC>, and tools.
      step_start "./build_all.sh"
      sh build_all.sh
      step_end "✓"
    else
      step_start "<YOUR TOOL LC> already built"
      step_end "✓"
    fi
  else
    step_start "<YOUR TOOL LC> already built"
    step_end "✓"
  fi

  [ -f "$<YOUR TOOL LC>" ] # A <YOUR TOOL LC> executable must exist at this point to proceed
  [ -f "./koch" ] || <YOUR TOOL ELC>_build_koch "$<YOUR TOOL LC>"
  [ -f "./bin/<YOUR TOOL LC>" ] || <YOUR TOOL ELC>_build_<YOUR TOOL LC>
}

<YOUR TOOL ELC>_build_koch() {
  local <YOUR TOOL LC>
  <YOUR TOOL LC>="$1"
  step_start "build koch"
  cd "$ASDF_DOWNLOAD_PATH"
  # shellcheck disable=SC2046
  eval "$<YOUR TOOL LC>" c --skipParentCfg:on $(printf ' %q ' "${<YOUR TOOL UC>_ARGS[@]}") koch
  step_end "✓"
}

<YOUR TOOL ELC>_build_<YOUR TOOL LC>() {
  step_start "build <YOUR TOOL LC>"
  cd "$ASDF_DOWNLOAD_PATH"
  # shellcheck disable=SC2046
  eval ./koch boot $(printf ' %q ' "${<YOUR TOOL UC>_ARGS[@]}")
  step_end "✓"
}

<YOUR TOOL ELC>_build_tools() {
  step_start "build tools"
  cd "$ASDF_DOWNLOAD_PATH"
  # shellcheck disable=SC2046
  eval ./koch tools $(printf ' %q ' "${<YOUR TOOL UC>_ARGS[@]}")
  step_end "✓"
}

<YOUR TOOL ELC>_build_<YOUR TOOL LC>() {
  step_start "build <YOUR TOOL LC>"
  cd "$ASDF_DOWNLOAD_PATH"
  # shellcheck disable=SC2046
  eval ./koch <YOUR TOOL LC> $(printf ' %q ' "${<YOUR TOOL UC>_ARGS[@]}")
  step_end "✓"
}

# Build <YOUR TOOL ULC> binaries in <YOUR TOOL EUC>_DOWNLOAD_PATH.
<YOUR TOOL ELC>_build() {
  section_start "II.  Build (${ASDF_DOWNLOAD_PATH//${HOME}/\~})"

  cd "$ASDF_DOWNLOAD_PATH"
  local bootstrap
  bootstrap=n
  local build_tools
  build_tools=n
  local build_<YOUR TOOL LC>
  build_<YOUR TOOL LC>=n
  [ -f "./bin/<YOUR TOOL LC>" ] || bootstrap=y
  [ -f "./bin/<YOUR TOOL LC>grep" ] || build_tools=y
  [ -f "./bin/<YOUR TOOL LC>" ] || build_<YOUR TOOL LC>=y

  if [ "$bootstrap" = "n" ] && [ "$build_tools" = "n" ] && [ "$build_<YOUR TOOL LC>" = "n" ]; then
    step_start "already built"
    step_end "✓"
    return 0
  fi

  [ "$bootstrap" = "n" ] || <YOUR TOOL ELC>_bootstrap_<YOUR TOOL LC>
  [ "$build_tools" = "n" ] || <YOUR TOOL ELC>_build_tools
  [ "$build_<YOUR TOOL LC>" = "n" ] || <YOUR TOOL ELC>_build_<YOUR TOOL LC>
}

<YOUR TOOL ELC>_time() {
  local start
  start="$(cat "${<YOUR TOOL EUC>_TEMP}/download.start" 2>/dev/null || true)"
  if [ -n "$start" ]; then
    local now
    now="$(date +%s)"
    local secs
    secs="$((now - start))"
    local mins
    mins="0"
    if [[ $secs -ge 60 ]]; then
      local time_mins
      time_mins="$(echo "scale=2; ${secs}/60" | bc)"
      mins="$(echo "${time_mins}" | cut -d'.' -f1)"
      secs="0.$(echo "${time_mins}" | cut -d'.' -f2)"
      secs="$(echo "${secs}"*60 | bc | awk '{print int($1+0.5)}')"
    fi
    echo " in ${mins}m${secs}s"
  fi
}
