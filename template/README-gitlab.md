<div align="center">

# <YOUR TOOL> ![Build Status](<TOOL REPO>/badges/<PRIMARY BRANCH>/pipeline.svg)[![Join the chat at https://gitter.im/<YOUR TOOL LC>/community](https://badges.gitter.im/<YOUR TOOL LC>/community.svg)](https://gitter.im/<YOUR TOOL LC>/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[<YOUR TOOL>](<TOOL HOMEPAGE>) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

**TODO: adapt these sections below**

- `bash`, `curl`, `tar`: and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- `SOME_ENV_VAR`: set this environment variable in your shell config to load the correct version of tool x.

# Install

[Install asdf](https://asdf-vm.com/guide/getting-started.html), then:

Plugin:


```sh
asdf plugin add <YOUR TOOL LC> # install the <YOUR TOOL LC> plugin
# or
asdf plugin add <TOOL REPO>.git

asdf <YOUR TOOL LC> install-deps  # install system-specific dependencies for downloading & building <YOUR TOOL ULC>
```

### To install <YOUR TOOL ULC>:

When available for the version and platform, the plugin will install pre-compiled binaries of <YOUR TOOL ULC>. If no binaries are available the plugin will build <YOUR TOOL ULC> from source.

```sh
# latest stable version of <YOUR TOOL ULC>
asdf install <YOUR TOOL LC> latest
# or latest stable minor/patch release of <YOUR TOOL ULC> 1.x.x
asdf install <YOUR TOOL LC> latest:1
# or latest stable patch release of <YOUR TOOL ULC> 1.6.x
asdf install <YOUR TOOL LC> latest:1.6
# or specific patch release
asdf install <YOUR TOOL LC> 1.6.8
```

### To install a nightly build of <YOUR TOOL ULC>:

```sh
# nightly unstable build of devel branch
asdf install <YOUR TOOL LC> ref:devel
# or nightly unstable build of version-1-6 branch, i.e. the latest 1.6.x release + any recent backports from devel
asdf install <YOUR TOOL LC> ref:version-1-6
# or nightly unstable build of version-1-4 branch, i.e. the latest 1.4.x release + any recent backports from devel
asdf install <YOUR TOOL LC> ref:version-1-4
# or nightly unstable build of version-1-2 branch, i.e. the 1.2.x release + any recent backports from devel
asdf install <YOUR TOOL LC> ref:version-1-2
# or nightly unstable build of version-1-0 branch, i.e. the 1.0.x release + any recent backports from devel
asdf install <YOUR TOOL LC> ref:version-1-0
```

### To build a specific git commit or branch of <YOUR TOOL ULC>:

```sh
# build using latest commit from the devel branch
asdf install <YOUR TOOL LC> ref:HEAD
# build using the specific commit 7d15fdd
asdf install <YOUR TOOL LC> ref:7d15fdd
# build using the tagged release v1.6.8
asdf install <YOUR TOOL LC> ref:v1.6.8
```


<YOUR TOOL>:

```shell
# Show all installable versions
asdf list-all <YOUR TOOL>

# Install specific version
asdf install <YOUR TOOL> latest

# Set a version globally (on your ~/.tool-versions file)
asdf global <YOUR TOOL> latest

# Now <YOUR TOOL> commands are available
<TOOL CHECK>
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.


# <YOUR TOOL LC>

<YOUR TOOL LC> allows you to quickly install any version of [<YOUR TOOL ULC>](https://<YOUR TOOL LC>-lang.org).

<YOUR TOOL LC> is intended for end-users and continuous integration. Whether macOS or Linux, x86 or ARM - all you'll need to install <YOUR TOOL ULC> is bash.



### To set the default version of <YOUR TOOL ULC> for your user:

```sh
asdf global <YOUR TOOL LC> latest:1.6
```

This creates a `.tool-versions` file in your home directory specifying the <YOUR TOOL ULC> version.

### To set the version of <YOUR TOOL ULC> for a project directory:

```sh
cd my-project
asdf local <YOUR TOOL LC> latest:1.6
```

This creates a `.tool-versions` file in the current directory specifying the <YOUR TOOL ULC> version. For additional plugin usage see the [asdf documentation](https://asdf-vm.com/#/core-manage-asdf).

## <YOUR TOOL LC> packages

<YOUR TOOL LC> packages are installed in `~/.asdf/installs/<YOUR TOOL LC>/<<YOUR TOOL LC>-version>/<YOUR TOOL LC>/pkgs`, unless a `<YOUR TOOL LC>deps` directory exists in the directory where `<YOUR TOOL LC> install` is run from.

See the [<YOUR TOOL LC> documentation](https://github.com/<YOUR TOOL LC>-lang/<YOUR TOOL LC>#<YOUR TOOL LC>s-folder-structure-and-packages) for more information about <YOUR TOOL LC>deps.

## Continuous Integration

### A simple example using GitHub Actions:

```yaml
name: Build
on:
  push:
    paths-ignore:
      - README.md

env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

jobs:
  build:
    name: Test
    runs-on: ${{ matrix.os }}
    matrix:
      include:
        # Test against stable <YOUR TOOL ULC> builds on linux
        - os: ubuntu-latest
          <YOUR TOOL LC>-version: latest:1.6
        - os: ubuntu-latest
          <YOUR TOOL LC>-version: latest:1.4

        # Test against unstable nightly <YOUR TOOL ULC> builds on macos (faster than building from source)
        - os: macos-latest
          <YOUR TOOL LC>-version: ref:version-1-6
        - os: macos-latest
          <YOUR TOOL LC>-version: ref:version-1-4
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Install <YOUR TOOL ULC>
        uses: asdf-vm/actions/install@v1
        with:
          tool_versions: |
            <YOUR TOOL LC> ${{ matrix.<YOUR TOOL LC>-version }}
      - name: Run tests
        run: |
          asdf local <YOUR TOOL LC> ${{ matrix.<YOUR TOOL LC>-version }}
          <YOUR TOOL LC> develop -y
          <YOUR TOOL LC> test
          <YOUR TOOL LC> examples
```

### Continuous Integration on Non-x86 Architectures

Using [uraimo/run-on-arch-action](https://github.com/uraimo/run-on-arch-action):

```yaml
name: Build
on:
  push:
    paths-ignore:
      - README.md

jobs:
  test_non_x86:
    name: Test <YOUR TOOL LC>-${{ matrix.<YOUR TOOL LC>-version }} / debian-buster / ${{ matrix.arch }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - <YOUR TOOL LC>-version: ref:version-1-6
            arch: armv7
          - <YOUR TOOL LC>-version: ref:version-1-2
            arch: aarch64

    runs-on: ubuntu-latest
    steps:
      - name: Checkout <YOUR TOOL ULC> project
        uses: actions/checkout@v2

      - uses: uraimo/run-on-arch-action@v2
        name: Install <YOUR TOOL ULC> & run tests
        with:
          arch: ${{ matrix.arch }}
          distro: buster

          dockerRunArgs: |
            --volume "${HOME}/.cache:/root/.cache"

          setup: mkdir -p "${HOME}/.cache"

          shell: /usr/bin/env bash

          install: |
            set -uexo pipefail
            # Install asdf and dependencies
            apt-get update -q -y
            apt-get -qq install -y build-essential curl git
            git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf" --branch v0.10.2

          env: |
            GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

          run: |
            set -uexo pipefail
            . "${HOME}/.asdf/asdf.sh"

            # Install <YOUR TOOL LC> and dependencies
            git clone <TOOL REPO>.git ~/<YOUR TOOL LC> --branch main --depth 1
            asdf plugin add <YOUR TOOL LC> ~/<YOUR TOOL LC>
            asdf <YOUR TOOL LC> install-deps -y

            # Install <YOUR TOOL ULC>
            asdf install <YOUR TOOL LC> ${{ matrix.<YOUR TOOL LC>-version }}
            asdf local <YOUR TOOL LC> ${{ matrix.<YOUR TOOL LC>-version }}

            # Run tests
            <YOUR TOOL LC> develop -y
            <YOUR TOOL LC> test
            <YOUR TOOL LC> examples
```

## Stable binaries

[<YOUR TOOL LC>-lang.org](https://<YOUR TOOL LC>-lang.org/install.html) supplies pre-compiled stable binaries of <YOUR TOOL ULC> for:

Linux:

- `x86_64` (gnu libc)
- `x86` (gnu libc)

## Unstable nightly binaries

[<YOUR TOOL LC>-lang/nightlies](https://github.com/<YOUR TOOL LC>-lang/nightlies) supplies pre-compiled unstable binaries of <YOUR TOOL ULC> for:

Linux:

- `x86_64` (gnu libc)
- `x86` (gnu libc)
- `aaarch64` (gnu libc)
- `armv7l` (gnu libc)

macOS:

- `x86_64`

## Updating asdf and <YOUR TOOL LC>

```sh
asdf update
asdf plugin update <YOUR TOOL LC> main
```


### Testing

This project uses [bats](https://github.com/bats-core/bats-core) for unit testing. Please follow existing patterns and add unit tests for your changeset. Dev dependencies for unit tests are installed via:

```shell
cd ~/.asdf/plugins/<YOUR TOOL LC>
npm install --include=dev
```

Run tests with:

```sh
npm run test
```

### Linting

This project uses [lintball](https://github.com/elijahr/lintball) to auto-format code. Please ensure your changeset passes linting. Enable the githooks with:

```sh
git config --local core.hooksPath .githooks
```


## Contributing

Contributions of any kind and pull requests welcome! See the [contributing guide](contributing.md).

Fork this repo, then run:

```sh
rm -rf ~/.asdf/plugins/<YOUR TOOL LC>
git clone git@<GIT TYPE>.com:<your-username>/<YOUR TOOL LC>.git ~/.asdf/plugins/<YOUR TOOL LC>
```

[Thanks goes to these contributors](<TOOL REPO>/graphs/<PRIMARY BRANCH>)!

# License

See [LICENSE](LICENSE) © [<YOUR NAME>](https://<GIT TYPE>.com/<YOUR GIT USERNAME>/)


**TODO: adapt these sections above**
