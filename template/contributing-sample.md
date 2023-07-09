# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

#
asdf plugin test <YOUR TOOL LC> https://github.com/<YOUR GITHUB USERNAME>/asdf-<YOUR TOOL LC>.git "<YOUR TOOL LC> -v"
```

Tests are automatically run in GitHub Actions on push and PR.
