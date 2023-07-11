<h1 align="center"><PROJECT NAME></h1>

## TODO: review and adopt Contributing

# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

# TODO: adapt this
asdf plugin test <YOUR TOOL> <TOOL REPO>.git "<TOOL CHECK>"
```

Tests are automatically run in GitHub Actions on push and PR.

## Team Members

- Owner: [<YOUR GIT USERNAME>](<TOOL REPO>)

## Contributing Index

- [Adding new features][new-features-hook]
- [Adding a translation][translation-hook]
- [Other contributions][other-contributions-hook]

## Adding new features [[↑][index]]

First of all, thank you for taking the time to contribute to this project!
Here are the **steps** involved when making a contribution:

- Make a **fork** of this repository
- **Clone** the fork locally
- Make the **changes and additions** desired to the cloned fork
- **Modify** the [CHANGELOG.md][changelog] file, following its structure.
- **Modify** [CITATION.cff][citation] file, updating their **version number** using [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- Add the following **header** to newly added code files:

```
/**
 * @license <YOUR TOOL>
 * filename.ext
 *
 * Copyright (c) 202x, <YOUR GIT USERNAME>.
 *
 * This source code is licensed under the GNU license found in the
 * LICENSE file in the root directory of this source tree.
 */
```

- **Add** yourself or your organization to the [CONTRIBUTORS.md][contributors] file, following its structure.
- Git **add**, **commit**, and **push** those changes.
- Open a new pull request which will be usually reviewed in less than three days.

## Adding a translation [[↑][index]]

First of all, thanks for taking the time to contribute to this project!
Usually, the process of making a translation is quite **similar** to any other contribution, so follow the steps explained [here][new-features-hook].

## Other contributions [[↑][index]]

You can even contribute by adding new enhancement and improvement **ideas** to the [ideas discussion][ideas-discussion] or lending someone a hand in the repository!


[index]: <TOOL REPO>/blob/master/CONTRIBUTING.md#contributing-index
[changelog]: ./CHANGELOG.md
[citation]: ./CITATION.cff
[contributors]: ./CONTRIBUTORS.md
[new-features-hook]: <TOOL REPO>/blob/master/CONTRIBUTING.md#adding-new-features-
[translation-hook]: <TOOL REPO>/blob/master/CONTRIBUTING.md#adding-a-translation-
[other-contributions-hook]: <TOOL REPO>/blob/master/CONTRIBUTING.md#other-contributions-
[ideas-discussion]: <TOOL REPO>/discussions/new?category=ideas
