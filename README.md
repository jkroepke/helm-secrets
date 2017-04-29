## Plugin for secrets management using Mozilla SOPS as backend

First internal version of plugin used pure pgp and whole secret file was encrypted as one.

Current version of plugin using Golang sops as backend which could be integrated in future into Helm itself, but currently it is only shell wrapper.

What kind of problems this plugins solves:
* Simple replacable layer integrated with helm command for encrypt, decrypt, view secrets files stored in any place. Currently using SOPS as backend.
* [Support for YAML/JSON structures encryption - Helm YAML secrets files](https://github.com/mozilla/sops#important-information-on-types)
* [Encryption per value where visual Diff should work even on encrypted files](https://github.com/mozilla/sops/blob/master/example.yaml)
* [On the fly decryption for git diff](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)
* On the fly decryption and cleanup for helm install/upgrade with this plugin helm bash command wrapper
* [Multiple key managment solutions like pgp and AWS KMS at same time](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
* [Simple addind/removing keys](https://github.com/mozilla/sops#adding-and-removing-keys)
* [With AWS KMS permissions managment for keys](https://aws.amazon.com/kms/)
* [Secrets files directory tree seperation with recursive .sops.yaml files search](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
* [Extracting sub elements from encrypted file structure](https://github.com/mozilla/sops#extract-a-sub-part-of-a-document-tree)
* [Encrypt only part of file if needed](https://github.com/mozilla/sops#encrypting-only-parts-of-a-file). [Example encrypted file](https://github.com/mozilla/sops/blob/master/example.yaml)

### Usage
```
$ helm secrets help
```
#### Available commands:
```
  enc           Encrypt chart secrets file
  dec           Decrypt chart secrets file
  dec-deps      Decrypt chart's dependecies' secrets files
  view          Print chart secrets decrypted
  edit          Edit chart secrets and ecrypt at the end
```
Any of this command have it's own help

#### SOPS as alternative usage in shell
As alternative you can use sops for example for edit just type
```
sops <SECRET_FILE_PATH>
```
Mozilla sops official [usage page](https://github.com/mozilla/sops#id2)

### Install

#### SOPS install
Before helm-secrets plugin install [Mozilla SOPS](https://github.com/mozilla/sops)

For MacOS
```
brew install sops
```
For Linux RPM or DEB, sops is available here: [Dist Packages](https://go.mozilla.org/sops/dist/)

#### Using Helm plugin manager (> 2.3.x)

```
helm plugin install https://github.com/futuresimple/helm-secrets
```

#### Pre Helm 2.3.0 Installation
Get a release tarball from the [releases](https://github.com/futuresimple/helm-secrets/releases) page.

Unpack the tarball in your helm plugins directory (```${HELM_HOME}/plugins```).

For example:
```
curl -L $TARBALL_URL | tar -C ${HELM_HOME}/plugins -xzv
```

### Real life use cases/examples


