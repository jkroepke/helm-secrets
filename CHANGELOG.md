# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Don't check if file exists on edit (https://github.com/jkroepke/helm-secrets/pull/31)
- Better Windows support (https://github.com/jkroepke/helm-secrets/pull/28)

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


[Unreleased]: https://github.com/jkroepke/helm-secrets/compare/v3.2.0...HEAD
[3.2.0]: https://github.com/jkroepke/helm-secrets/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/jkroepke/helm-secrets/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/jkroepke/helm-secrets/compare/5f91bdf...v3.0.0
