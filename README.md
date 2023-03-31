# PHPCS CI

This repository is for the **GitHub Action** to run PHPCS on your codebase. It is a simple combination of the [PHP CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) with multiple coding standards to check your code against.

**The end goal of this tool:**

- Run PHPCS on your codebase.
- Help your code to following the coding standards.
- Automate the process to help streamline code reviews using GitHub checks API.

## How it Works

The phpcs-ci finds issues and reports them to the console output based on the ruleset you provide. Fixes are suggested in the console output but not automatically fixed.

Behind the scenes it uses the [PHP CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) which is pre-installed in the Docker image, to avoid setting up PHP and PHPCS in the CI environment. Since this is a Docker image, it works best in the self-hosted runners.

## Usage

```yml
---
name: PHPCS CI

on:
  pull_request:
    branches: [master, main]

jobs:
  phpcs:
    name: Lint Code Base
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Lint Code Base
        uses: thelovekesh/phpcs-ci@v1
```

### License

- [MIT License](https://github.com/github/super-linter/blob/main/LICENSE)
