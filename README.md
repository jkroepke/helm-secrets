
[![License](https://img.shields.io/github/license/futuresimple/helm-secrets.svg)](https://github.com/futuresimple/helm-secrets/blob/master/LICENSE)
[![Current Release](https://img.shields.io/github/release/futuresimple/helm-secrets.svg)](https://github.com/futuresimple/helm-secrets/releases/latest)
[![Production Ready](https://img.shields.io/badge/production-ready-green.svg)](https://github.com/futuresimple/helm-secrets/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/futuresimple/helm-secrets.svg)](https://github.com/futuresimple/helm-secrets/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/futuresimple/helm-secrets.svg?style=flat-square)](https://github.com/futuresimple/helm-secrets/pulls)

# Plugin for secrets management in Helm

Developed and used on all environments in [BaseCRM](https://getbase.com/).

First internal version of the plugin used pure PGP and the whole secret file was encrypted as one.

A current version of the plugin using Golang sops as backend which could be integrated in future into Helm itself, but currently, it is only shell wrapper.

What kind of problems this plugin solves:
* Simple replaceable layer integrated with helm command for encrypting, decrypting, view secrets files stored in any place. Currently using SOPS as backend.
* [Support for YAML/JSON structures encryption - Helm YAML secrets files](https://github.com/mozilla/sops#important-information-on-types)
* [Encryption per value where visual Diff should work even on encrypted files](https://github.com/mozilla/sops/blob/master/example.yaml)
* [On the fly decryption for git diff](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)
* On the fly decryption and cleanup for helm install/upgrade with this plugin helm bash command wrapper
* [Multiple key management solutions like PGP and AWS KMS at same time](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
* [Simple adding/removing keys](https://github.com/mozilla/sops#adding-and-removing-keys)
* [With AWS KMS permissions managment for keys](https://aws.amazon.com/kms/)
* [Secrets files directory tree seperation with recursive .sops.yaml files search](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
* [Extracting sub elements from encrypted file structure](https://github.com/mozilla/sops#extract-a-sub-part-of-a-document-tree)
* [Encrypt only part of a file if needed](https://github.com/mozilla/sops#encrypting-only-parts-of-a-file). [Example encrypted file](https://github.com/mozilla/sops/blob/master/example.yaml)

## Moving parts of project

```helm-wrapper``` - It is not a part of Helm project itself. It is just simple wrapper in shell that run helm bellow but wrapping secrets decryption and cleaning on-the-fly, before and after Helm run. Created from install-binary.sh in helm-secrets plugin install process as hook action making symlink to wrapper.sh. This should be used as default command to operate with Helm client with helm-secrets installed.

```test.sh``` - Test script to check if all parts of plugin works. Using example dir with vars structure and pgp keys to make real tests on real data with real encryption/decryption.

```install-binary.sh``` - Script used as hook to install helm-wrapper, download and install sops and install git diff configuration for helm-secret files.

```secrets.sh``` - Main helm-secrets plugin code for all helm-secrets plugin actions available in ```helm secrets help``` after plugin install

## Install

#### SOPS install
Just install plugin using ```helm plugin install https://github.com/futuresimple/helm-secrets``` and sops will be installed using hook when helm > 2.3.x

You can always install manually for MacOS:
```
brew install sops
```
For Linux RPM or DEB, sops is available here: [Dist Packages](https://go.mozilla.org/sops/dist/)

#### SOPS git diff
Git config part is installed with a plugin but to be fully functional need ```.gitattributes``` file inside the root directory of charts repo with content
```
*.yaml diff=sopsdiffer
```
More info on [sops page](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)

#### Using Helm plugin manager (> 2.3.x)

```
helm plugin install https://github.com/futuresimple/helm-secrets
```

#### Pre Helm 2.3.0 Installation
Get a release tarball from the [releases](https://github.com/futuresimple/helm-secrets/releases) page.

Unpack the tarball in your helm plugins directory (```$(helm home)/plugins```).

For example:
```
curl -L $TARBALL_URL | tar -C $(helm home)/plugins -xzv
```

#### Helm-wrapper configuration
By default helm-wrapper is configured to not encrypt/decrypt secrets.yaml in charts templates.
Set your own options as ENV variables if you like:
```
DECRYPT_CHARTS=false helm-wrapper ....
```
If you'd like to use it in a different way just change this line.

## Usage and examples

```
$ helm secrets help
```
#### Available commands:
```
  enc           Encrypt chart secrets file
  dec           Decrypt chart secrets file
  dec-deps      Decrypt chart's dependencies' secrets files
  view          Print chart secrets decrypted
  edit          Edit chart secrets and encrypt at the end
```
Any of this command have its own help

## Use case

We use vars for Helm Charts from separate directory tree with structure like this:
```
helm_vars/
├── .sops.yaml
├── projectX
|   ├── .sops.yaml
│   ├── production
│   │   └── us-east-1
│   │       └── java-app
│   │           └── hello-world
│   │               ├── secrets.yaml
│   │               └── values.yaml
│   ├── sandbox
│   │   └── us-east-1
│   │       └── java-app
│   │           └── hello-world
│   │               ├── secrets.yaml
│   │               └── values.yaml
|   ├── secrets.yaml
│   └── values.yaml
├── projectY
|   ├── .sops.yaml
│   ├── production
│   │   └── us-east-1
│   │       └── java-app
│   │           └── hello-world
│   │               ├── secrets.yaml
│   │               └── values.yaml
│   ├── sandbox
│   │   └── us-east-1
│   │       └── java-app
│   │           └── hello-world
│   │               ├── secrets.yaml
│   │               └── values.yaml
|   ├── secrets.yaml
│   └── values.yaml
├── secrets.yaml
└── values.yaml
```
As you can see we can run different PGP or KMS keys per project, globally or per any tree level. Thanks to this we can isolate tree on different CI/CD instances using same GIT repository.
As we use simple -f option when running helm-wrapper we can just use encrypted secrets.yaml and all this secrets will be decrypted and cleaned on the fly before and after helm run.

```.sops.yaml``` file example
```
---
creation_rules:
        # Encrypt with AWS KMS
        - kms: 'arn:aws:kms:us-east-1:222222222222:key/111b1c11-1c11-1fd1-aa11-a1c1a1sa1dsl1+arn:aws:iam::222222222222:role/helm_secrets'

        # As failover encrypt with PGP
          pgp: '000111122223333444AAAADDDDFFFFGGGG000999'

        # For more help look at https://github.com/mozilla/sops
```
Multiple KMS and PGP are allowed.

Everything is described in SOPS docs - links in this project description.

## Tips

#### Prevent committing decrypted files to git
If you like to secure situation when decrypted file is committed by mistake to git you can add your secrets.yaml.dec files to you charts project .gitignore

As the second level of securing this situation is to add for example ```.sopscommithook``` file inside your charts repository local commit hook.
This will prevent committing decrypted files without sops metadata.

```.sopscommithook``` content example:
```
#!/bin/sh

for FILE in $(git diff-index HEAD --name-only | grep <your vars dir> | grep "secrets.y"); do
    if [ -f "$FILE" ] && ! grep -C10000 "sops:" $FILE | grep -q "version:"; then
    then
        echo "!!!!! $FILE" 'File is not encrypted !!!!!'
        echo "Run: helm secrets enc <file path>"
        exit 1
    fi
done
exit
```
