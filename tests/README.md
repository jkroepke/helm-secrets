# helm-secrets test suite

This tests suite use the [bats-core](https://github.com/bats-core/bats-core) framework.

Some test extension libraries are included in this project as git submodule.

Run
```bash
git submodule update --init --force
```
to checkout the submodules.

## Wording

Inside helm-secrets we have 2 groups of tests:

* **unit tests**

  Can be run without an reachable kubernetes cluster
  Located under [./unit/](./unit)

* **integration tests**

  Depends against a reachable kubernetes cluster
  Located under [./it/](./it)

## Requirements

To execute the tests have to install some utilities first.

### bats
Then follow the installation instruction for bats here: https://github.com/bats-core/bats-core#installation

More information's here: https://github.com/bats-core/bats-core

### sops
Can be downloaded here: https://github.com/mozilla/sops/releases

Alternately available via [homebrew](https://brew.sh/):

```bash
brew install sops
```

More information's here: https://github.com/mozilla/sops

### gpg
sops only non-public cloud encryption method based on gpg.

Alternately available via [homebrew](https://brew.sh/):
```bash
brew info gnupg
```

On Linux use your package manager to install gpg if it's not already installed.

### vault-cli (optional)
The vault cli is only required to run the tests with the `HELM_SECRETS_BACKEND=vault` environment variable.

You could download vault here: https://www.vaultproject.io/downloads

Alternately available via [homebrew](https://brew.sh/):
```bash
brew info vault
```

## Run

If possible start the tests from the root of the repository. Then execute:

```bash
# Unit Tests
bats -r tests/unit

# IT Tests
bats -r tests/it
```

If bats is not installed locally, you could run bats directory from this repo:

```bash
# Unit Tests
./tests/bats/core/bin/bats -r tests/unit

# IT Tests
./tests/bats/core/bin/bats -r tests/it
```

This method is described as "Run bats from source" inside the bats-core documentation.

More information about running single tests or filtering tests can be found here: https://github.com/bats-core/bats-core#usage

By default, the sops backend is selected for tests. 
If you want to test another secret backend like [vals](../scripts/lib/backends/vals.sh), you could do it by env variable `HELM_SECRETS_BACKEND=vals`.

```bash
# Unit Tests
HELM_SECRETS_BACKEND=vault bats -r tests/unit

# IT Tests
HELM_SECRETS_BACKEND=vault bats -r tests/it
```

The vault tests require a reachable vault server. Start one on you local machine by run:

```bash
vault server -dev -dev-root-token-id=test
```

The tests will seed the vault server as needed.
