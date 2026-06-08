# AGENTS.md

This repository is `helm-secrets`, a Helm plugin implemented mostly in POSIX shell. It decrypts Helm value files on demand, supports secret references through multiple backends, and integrates with Helm downloader and post-renderer plugin mechanisms.

## Project Map

- `plugin.yaml` is the Helm 3 plugin manifest. It registers the `secrets` command and downloader protocols.
- `plugins/helm-secrets-cli`, `plugins/helm-secrets-getter`, and `plugins/helm-secrets-post-renderer` contain Helm 4 plugin manifests. Helm 4 currently treats CLI, getter, and post-renderer plugins as separate plugin types, so these manifests are split even though Helm 3 can declare the command and downloader protocols together in `plugin.yaml`. Keep versions and user-facing help synchronized with `plugin.yaml` and `scripts/commands/help.sh`.
- `scripts/run.sh` is the main plugin entrypoint. It initializes globals, loads libraries/backends, parses top-level `helm secrets` options, then dispatches to command scripts.
- `scripts/commands/` contains subcommands and Helm integration:
  - `encrypt.sh`, `decrypt.sh`, `edit.sh` implement direct file operations.
  - `helm.sh` wraps arbitrary Helm commands, decrypts `-f`, `--values`, `--set-file`, and decrypts literals in `--set`, `--set-string`, and `--set-json`.
  - `downloader.sh` implements `secrets://`, `secrets+gpg-import://`, `secrets+gpg-import-kubernetes://`, `secrets+age-import://`, `secrets+age-import-kubernetes://`, and `secrets+literal://`.
  - `post-renderer.sh` evaluates `vals` references in rendered manifests when `--evaluate-templates` is enabled.
  - `help.sh` and `version.sh` provide user-facing CLI output.
- `scripts/lib/` contains shared shell functions for logging, traps, path handling, backend dispatch, file retrieval, HTTP downloads, and strict variable expansion.
- `scripts/lib/backends/` contains in-tree backends:
  - `sops.sh` is the default backend. It can encrypt, decrypt, edit, and detect SOPS-encrypted content.
  - `vals.sh` resolves `ref+...` references. It does not support encrypt or edit.
  - `noop.sh` passes files through for tests and non-encrypted workflows.
  - `_custom.sh` is a helper contract for out-of-tree backends.
- `scripts/lib/file/` abstracts value source retrieval:
  - `local.sh` handles normal files.
  - `http.sh` downloads `http://` and `https://` values with `curl` or `wget`.
  - `custom.sh` delegates arbitrary `*://` sources to Helm through a tiny chart in `helm-values-getter`.
- `scripts/wrapper/` contains wrapper scripts for Windows and optional automatic `helm secrets` forwarding.
- `docs/` is the wiki-style documentation source. Update docs when CLI flags, environment variables, security behavior, or integration behavior changes.
- `examples/` contains sample charts and backend scripts for SOPS, vals, Argo CD, Terraform, and custom backends.
- `tests/` contains first-party Bats tests and assets. `tests/bats/` is vendored/submodule test tooling; do not edit it unless intentionally updating submodules.

## Runtime Flow

1. Helm invokes `scripts/run.sh` through a plugin manifest.
2. `run.sh` sets `HELM_BIN`, `SCRIPT_DIR`, `TMPDIR`, default backend (`sops`), quiet mode, decrypted file naming settings, and feature flags from `HELM_SECRETS_*` environment variables.
3. It loads `common.sh`, `expand_vars_strict.sh`, `file.sh`, `backend.sh`, and `http.sh`, then calls `load_secret_backend`.
4. Top-level arguments are parsed before dispatch. Global flags such as `--backend`, `--backend-args`, `--quiet`, `--ignore-missing-values`, `--evaluate-templates`, and `--decrypt-secrets-in-tmp-dir` affect later command behavior.
5. Direct commands call backend helpers through `backend.sh`. Wrapped Helm commands source `commands/helm.sh`.
6. `helm_wrapper` rewrites Helm arguments:
   - For `-f`/`--values`, it fetches the source, decrypts encrypted files into `.dec` files or temp files, and passes decrypted paths to Helm.
   - For `secrets://...` values, prefer passing the protocol URL through to Helm so Helm's downloader plugin handles it directly. Avoid resolving `secrets://` through `_file_get` in the wrapper unless there is a specific compatibility reason and regression coverage for trailing newlines.
   - For `--set-file`, it decrypts file contents and preserves Helm key prefixes.
   - For `--set`, `--set-string`, and `--set-json`, it resolves encrypted literal values and preserves escaped commas, lists, and trailing newlines.
   - It records generated decrypted files and removes them in `_trap_hook`.
7. Downloader protocol handling in `downloader.sh` prints decrypted content to stdout for Helm downloader usage. Key-import protocols initialize temporary GPG homes or `SOPS_AGE_KEY_FILE` before decrypting.
8. If template evaluation is enabled, `helm.sh` injects a Helm post-renderer. Helm 3 invokes `helm secrets post-renderer`; Helm 4 uses the separate `secrets-post-renderer` plugin because Helm 4 plugin types are split.

## Backend Contract

Backends are dispatched by name through functions in `scripts/lib/backend.sh`. A backend named `foo` must provide:

- `_foo_backend_is_file_encrypted FILE`
- `_foo_backend_is_encrypted` reading stdin
- `_foo_backend_encrypt_file TYPE INPUT OUTPUT`
- `_foo_backend_decrypt_file TYPE INPUT [OUTPUT]`
- `_foo_backend_decrypt_literal VALUE`
- `_foo_backend_edit_file TYPE INPUT`

In-tree backend selection accepts `sops`, `vals`, and `noop`. Out-of-tree backends can be loaded by file path through `--backend` or `HELM_SECRETS_BACKEND`; they normally source `scripts/lib/backends/_custom.sh`. `HELM_SECRETS_ALLOWED_BACKENDS` restricts allowed backend names and is tested by the suite.

Backend-specific binary overrides:

- `HELM_SECRETS_SOPS_PATH` or legacy `HELM_SECRETS_SOPS_BIN`
- `HELM_SECRETS_VALS_PATH`
- `HELM_SECRETS_CURL_PATH`
- `HELM_SECRETS_WGET_PATH`
- `HELM_SECRETS_KUBECTL_PATH`

## Important Environment Variables

- `HELM_SECRETS_BACKEND`, `HELM_SECRETS_BACKEND_ARGS`, `HELM_SECRETS_ALLOWED_BACKENDS`
- `HELM_SECRETS_QUIET`; defaults to `true` in Argo CD when `ARGOCD_APP_NAME` is present
- `HELM_SECRETS_DEC_PREFIX`, `HELM_SECRETS_DEC_SUFFIX`, `HELM_SECRETS_DEC_DIR`, `HELM_SECRETS_DEC_TMP_DIR`
- `HELM_SECRETS_IGNORE_MISSING_VALUES`
- `HELM_SECRETS_EVALUATE_TEMPLATES`, `HELM_SECRETS_EVALUATE_TEMPLATES_DECODE_SECRETS`
- `HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR`
- `HELM_SECRETS_LOAD_GPG_KEYS`
- `HELM_SECRETS_URL_VARIABLE_EXPANSION`
- `HELM_SECRETS_VALUES_ALLOW_SYMLINKS`, `HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH`, `HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL`
- `HELM_SECRETS_ALLOW_GPG_IMPORT`, `HELM_SECRETS_ALLOW_GPG_IMPORT_KUBERNETES`, `HELM_SECRETS_ALLOW_AGE_IMPORT`, `HELM_SECRETS_ALLOW_AGE_IMPORT_KUBERNETES`
- `HELM_SECRETS_KEY_LOCATION_PREFIX`
- `HELM_SECRETS_WRAPPER_ENABLED`, `HELM_SECRETS_HELM_PATH`, `HELM_SECRET_WSL_INTEROP`

When adding a user-visible variable, update `scripts/commands/help.sh`, Helm 4 CLI help in `plugins/helm-secrets-cli/plugin.yaml`, docs, and tests.

## Portability Rules

- First-party plugin scripts under `scripts/` are POSIX `sh`, not Bash. They are tested under dash, ash, bash-as-sh, zsh-as-sh, posh, macOS `/bin/sh`, Cygwin, and WSL.
- Avoid Bash-only syntax in `scripts/**/*.sh`: no arrays, `[[ ]]`, process substitution, `local`, `${var//...}`, or `pipefail`.
- Files under `tests/`, including Bats tests and test helpers, may use Bash syntax because the test suite runs under Bash/Bats.
- Preserve careful quoting. This project handles paths with spaces, special characters, Windows paths, WSL path conversion, escaped commas, Helm set lists, and trailing newlines.
- Be cautious with command substitutions: POSIX shells strip trailing newlines. Existing code uses sentinel characters where preserving newlines matters.
- `pipefail` is not available in POSIX `sh`, so command substitutions need extra care. Multiple commands inside `$()` are dangerous because only the last command controls the substitution exit code. If a later command must run after a checked command, preserve the status explicitly, for example `$(cmd; status=$?; cmd2; exit "$status")`. This pattern may not work the same way with pipelines because pipeline status is also limited without `pipefail`.
- Do not rely on GNU-only tools unless guarded. macOS `sed -i` differs; use `_sed_i`.
- Keep generated decrypted files cleaned up via traps. Avoid leaving `.dec` files outside explicit inline operations.
- Do not edit vendored `tests/bats/**` unless the task is to update Bats submodules.

## Security-Sensitive Areas

- `scripts/lib/file.sh` enforces optional restrictions on symlinks, absolute paths, and `..` path traversal.
- `scripts/commands/downloader.sh` controls whether GPG/age key imports and Kubernetes key imports are allowed.
- `HELM_SECRETS_KEY_LOCATION_PREFIX` restricts key file locations for import protocols.
- `scripts/lib/file/http.sh` can expand environment variables inside URLs only when `HELM_SECRETS_URL_VARIABLE_EXPANSION=true`; keep this opt-in.
- Avoid logging decrypted secret values. Many tests assert quiet behavior and cleanup.

## Tests

Use the vendored Bats runner when Bats is not installed:

```sh
bash tests/bats/core/bin/bats -r tests/unit
```

Run backend-specific unit suites:

```sh
HELM_SECRETS_BACKEND=sops bash tests/bats/core/bin/bats -r tests/unit
HELM_SECRETS_BACKEND=vals bash tests/bats/core/bin/bats -r tests/unit
```

Integration tests require a reachable Kubernetes cluster:

```sh
bash tests/bats/core/bin/bats -r tests/it
```

Focused tests are usually enough while iterating, for example:

```sh
bash tests/bats/core/bin/bats tests/unit/template.bats
bash tests/bats/core/bin/bats tests/unit/secret-backends.bats
```

When changing wrapper handling for `--set`, `--set-string`, `--set-json`, `--set-file`, or downloader protocols, run at least one focused `vals` backend test as well as the default `sops` path. The default backend skips several vals-specific literal/reference tests, so a local green run with only `sops` can miss CI failures.

The test suite installs this repo as a Helm plugin into a temporary Helm home, imports test GPG keys from `tests/assets/gpg`, creates charts under `tests/.tmp/cache`, and copies value assets into each test temp directory. Unit tests do not require Kubernetes; integration tests cover install/upgrade/diff paths and Kubernetes key-import protocols.

Before running Bats, make sure a `gpg-agent` is running for the test GPG operations. Terminate it after the tests, for example with `gpgconf --kill gpg-agent`, so test state does not leak into later runs.

## CI Expectations

CI runs shell linting and checkbashisms, then unit tests across Linux, macOS, Windows, Cygwin, WSL, multiple shells, Helm 3 and Helm 4, SOPS, and vals. Coverage rewrites `env sh` to `env bash` only for bashcov; do not copy that pattern into normal code.

The current CI version pins are in `.github/workflows/ci.yaml`.

## Change Guidelines

- Keep behavior changes tightly scoped and add/adjust Bats tests near the affected behavior.
- Before committing, run `shfmt` and `shellcheck` on changed shell files.
- For new features or bug fixes only, add a line to `CHANGELOG.md`.
- For CLI behavior, update both Helm 3 and Helm 4 manifests/help text when needed.
- For backend changes, update `docs/Secret Backends.md` and backend tests.
- For downloader protocol or Argo CD behavior, update `docs/ArgoCD Integration.md`, `docs/ARGOCD.md`, and relevant template/install tests.
- For security defaults or restrictions, update `docs/Security in shared environments.md` and tests around `HELM_SECRETS_VALUES_ALLOW_*` or key import flags.
- Maintain LF endings except `scripts/wrapper/run.cmd`, which uses CRLF per `.editorconfig`.
- Do not commit generated decrypted files, coverage output, or `tests/.tmp` artifacts.
