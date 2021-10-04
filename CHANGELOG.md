# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Allow override sops version on installation

## [Unreleased]

### Added
- [vals](https://github.com/variantdev/vals) driver. vals supporting Vault, AWS SSM, GCP, sops, terraform states or other files.
- A better ArgoCD Integration. helm-secrets can load now gpg keys for you by using the uri `gpg-import+secrets://path/key.asc?path/secrets.yaml` as value file.
  Checkout the [docs/ARGOCD.md](docs/ARGOCD.md) to more information.

## [3.8.3] - 2021-08-06

### Changes
- Allow dot, asterisk and underscore for vault path

## [3.8.2] - 2021-07-14

### Fixed
- Decrypt partially encrypted sops files correctly

## [3.8.1] - 2021-06-12

### Fixed
- OUTPUT_DECRYPTED_FILE_PATH: parameter not set

## [3.8.0] - 2021-06-12

### Added
- New parameter `--output-decrypt-file-path` (`HELM_SECRETS_OUTPUT_DECRYPTED_FILE_PATH`) that outputs the path of decrypted files only.
- `HELM_SECRETS_DEC_PREFIX` variable in addition to `HELM_SECRETS_DEC_SUFFIX`
- New parameter `--version`
- cygwin compatibility

### Changes
- `HELM_SECRETS_DEC_SUFFIX` has been changed from `.yaml.dec` to `.dec`. Additionally, while append the suffix, the file extension `.yaml` is not stripped anymore.
- The detection of encrypted sops files has been changed. Instead, looking for `sops:` and `version:`, the string `unencrypted_suffix` is used now.

## [3.7.0] - 2021-05-22

### Added
- envsubst driver

### Changes
- Output errors on stderr

## [3.6.1] - 2021-03-30

### Fixes
- `mktemp: too few X's in template` error on Mac OS if gnu coreutils preferred over builtin bsd tools.

## [3.6.0] - 2021-03-29

### Breaking
The default sops installation is removed, since helm-secrets could use with hashicorp vault which does not require sops.

### Added
- Detect ArgoCD environment by `ARGOCD_APP_NAME` environment variable and set `HELM_SECRETS_QUIET=true` by default. (https://github.com/jkroepke/helm-secrets/pull/83)

### Fixes
- Cleanup all temporary files.

### Removed
- Sops installation

## [3.5.0] - 2021-02-20

### Added
- Added `--driver-args` to pass additional argument to underlying commands (https://github.com/jkroepke/helm-secrets/pull/82)

### Fixes
- "grep: Invalid range end" if locale is not C (https://github.com/jkroepke/helm-secrets/pull/81)

## [3.4.2] - 2021-02-19

### Changed
- Dev: Rename `master` branch to `main`

### Fixes
- "grep: Invalid range end" if locale is not C (https://github.com/jkroepke/helm-secrets/pull/79)

## [3.4.1] - 2021-01-23

### Fixes
- Handling `--` inside command line arguments
- Fix handling errors with remote files
- Strip yaml doc separator if vault driver is used (https://github.com/jkroepke/helm-secrets/pull/70)
- Incompatibilities if sed links to gnu sed on Mac OS (https://github.com/jkroepke/helm-secrets/pull/72)

## [3.4.0] - 2020-12-26

From this version, the installation on Helm 2 requires additional steps.
Check [README.md](README.md#installation-on-helm-2) 

### Added
- Implement alternate syntax (https://github.com/jkroepke/helm-secrets/pull/52)
- Remote values support (supporting http:// and helm downloader plugins) (https://github.com/jkroepke/helm-secrets/pull/54)
- Let downloader plugin supports remote files and all secrets drivers (https://github.com/jkroepke/helm-secrets/pull/55)
- Externalize custom vault driver logic. (https://github.com/jkroepke/helm-secrets/pull/63)
- Dev: Implement code coverage
- Dev: Test zsh compatibility

### Fixes
- Vault driver: If vault command failed, the script execution was not terminated. (https://github.com/jkroepke/helm-secrets/pull/61)

## [3.3.5] - 2020-10-16

### Added
- Better lookup for unix shells on Windows (https://github.com/jkroepke/helm-secrets/pull/42)

## [3.3.4] - 2020-09-09

### Added
- Allow overriding SOPS version on installation (https://github.com/jkroepke/helm-secrets/pull/40)
- Add separat download artefact on github release

## [3.3.0] - 2020-08-28

### Added
- Don't check if file exists on edit (https://github.com/jkroepke/helm-secrets/pull/31)
- Better Windows support (https://github.com/jkroepke/helm-secrets/pull/28)
- Support parameters like --values=secrets.yaml (https://github.com/jkroepke/helm-secrets/pull/34)
- Added CentOS 7 as supported OS system (https://github.com/jkroepke/helm-secrets/pull/35)

## [3.2.0] - 2020-05-08

### Added
- Add Vault support (https://github.com/jkroepke/helm-secrets/pull/22)
- Secret driver to gain secrets from other sources then sops. (https://github.com/jkroepke/helm-secrets/pull/16)
- Remove name restriction (https://github.com/jkroepke/helm-secrets/pull/23)

### Changed
- Run unit tests on bash, dash and ash (busybox), too.

## [3.1.0] - 2020-04-27

### Added

- completion.yaml for helm shell auto completion
- Tests for all `helm secrets` commands
- Added quiet flag for helm secrets (https://github.com/jkroepke/helm-secrets/pull/8)

### Changed

- Escape special chars in paths correctly (https://github.com/jkroepke/helm-secrets/pull/9)

## [3.0.0] - 2020-04-26

Started a fork of https://github.com/zendesk/helm-secrets

### Added
- POSIX compatibility (https://github.com/jkroepke/helm-secrets/pull/1)
- Optionally decrypt helm secrets in a temporary directory (https://github.com/jkroepke/helm-secrets/pull/5)
- Added CI tests (https://github.com/jkroepke/helm-secrets/pull/2)

### Changed
- Changed secrets.yaml prefix just to `secrets`. All files like `secrets*` are now decrypted
- Remove dependency against gnu-getops
- Remove run as root dependency on helm plugin install
- Verbose output is now on stderr
- Support all helm sub commands and plugins


[Unreleased]: https://github.com/jkroepke/helm-secrets/compare/v3.8.3...HEAD
[3.8.3]: https://github.com/jkroepke/helm-secrets/compare/v3.8.2...v3.8.3
[3.8.2]: https://github.com/jkroepke/helm-secrets/compare/v3.8.1...v3.8.2
[3.8.1]: https://github.com/jkroepke/helm-secrets/compare/v3.8.0...v3.8.1
[3.8.0]: https://github.com/jkroepke/helm-secrets/compare/v3.7.0...v3.8.0
[3.7.0]: https://github.com/jkroepke/helm-secrets/compare/v3.6.1...v3.7.0
[3.6.1]: https://github.com/jkroepke/helm-secrets/compare/v3.6.0...v3.6.1
[3.6.0]: https://github.com/jkroepke/helm-secrets/compare/v3.5.0...v3.6.0
[3.5.0]: https://github.com/jkroepke/helm-secrets/compare/v3.4.2...v3.5.0
[3.4.2]: https://github.com/jkroepke/helm-secrets/compare/v3.4.1...v3.4.2
[3.4.1]: https://github.com/jkroepke/helm-secrets/compare/v3.4.0...v3.4.1
[3.4.0]: https://github.com/jkroepke/helm-secrets/compare/v3.3.5...v3.4.0
[3.3.5]: https://github.com/jkroepke/helm-secrets/compare/v3.3.4...v3.3.5
[3.3.4]: https://github.com/jkroepke/helm-secrets/compare/v3.3.0...v3.3.4
[3.3.0]: https://github.com/jkroepke/helm-secrets/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/jkroepke/helm-secrets/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/jkroepke/helm-secrets/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/jkroepke/helm-secrets/compare/5f91bdf...v3.0.0
