
[![License](https://img.shields.io/github/license/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/blob/master/LICENSE)
[![Current Release](https://img.shields.io/github/release/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![Production Ready](https://img.shields.io/badge/production-ready-green.svg)](https://github.com/jkroepke/helm-secrets/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/jkroepke/helm-secrets.svg)](https://github.com/jkroepke/helm-secrets/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/jkroepke/helm-secrets.svg?style=flat-square)](https://github.com/jkroepke/helm-secrets/pulls)

# Plugin for secrets management in Helm

Developed and used in all environments in [BaseCRM](https://getbase.com/).

# how we use it ?

We store secrets and values in ```helm_vars``` dir structure just like in this repository example dir. All this data versioned in GIT.
Working in teams on multiple projects/regions/envs and multiple secrets files at once.
We have Makefile in our Helm charts repo to simplify install helm-secrets plugin with helm and other stuff we use. Same Makefile used to rebuild all helm charts with dependencies and some other everyday helpers.
Encrypting, Decrypting, Editing secrets on local clones, making #PR's and storing this in our helm charts repo encrypted with PGP, AWS KMS and GCP KMS.
Deploying using helm-wrapper from local or from CI with same charts and secrets/values from GIT repository.

# Main features

A first internal version of the plugin used pure PGP and the whole secret file was encrypted as one.
A current version of the plugin using Golang sops as backend which could be integrated in future into Helm itself, but currently, it is only shell wrapper.

What kind of problems this plugin solves:
* Simple replaceable layer integrated with helm command for encrypting, decrypting, view secrets files stored in any place. Currently using SOPS as backend.
* [Support for YAML/JSON structures encryption - Helm YAML secrets files](https://github.com/mozilla/sops#important-information-on-types)
* [Encryption per value where visual Diff should work even on encrypted files](https://github.com/mozilla/sops/blob/master/example.yaml)
* [On the fly decryption for git diff](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)
* On the fly decryption and cleanup for helm install/upgrade with a helm command wrapper
* [Multiple key management solutions like PGP, AWS KMS and GCP KMS at same time](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
* [Simple adding/removing keys](https://github.com/mozilla/sops#adding-and-removing-keys)
* [With AWS KMS permissions management for keys](https://aws.amazon.com/kms/)
* [Secrets files directory tree separation with recursive .sops.yaml files search](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
* [Extracting sub-elements from encrypted file structure](https://github.com/mozilla/sops#extract-a-sub-part-of-a-document-tree)
* [Encrypt only part of a file if needed](https://github.com/mozilla/sops#encrypting-only-parts-of-a-file). [Example encrypted file](https://github.com/mozilla/sops/blob/master/example.yaml)

## Moving parts of project

```helm-wrapper``` - It is not a part of Helm project itself. It is a just simple wrapper in the shell that runs helm within but wrapping secret decryption and cleaning on-the-fly, before and after Helm run. It is created from install-binary.sh in helm-secrets plugin install process as hook action making the symlink to wrapper.sh. This should be used as default command to operate with Helm client with helm-secrets installed.

```test.sh``` - Test script to check if all parts of the plugin work. Using example dir with vars structure and PGP keys to make real tests on real data with real encryption/decryption.

```install-binary.sh``` - Script used as the hook to download and install sops and install git diff configuration for helm-secrets files.

```secrets.sh``` - Main helm-secrets plugin code for all helm-secrets plugin actions available in ```helm secrets help``` after plugin install

## Installation and Dependencies

#### SOPS install
Just install the plugin using ```helm plugin install https://github.com/jkroepke/helm-secrets``` and sops will be installed as part of it, using hook when helm > 2.3.x

You can always install manually in MacOS as below:
```
brew install sops
```
For Linux RPM or DEB, sops is available here: [Dist Packages](https://github.com/mozilla/sops/releases)

#### SOPS git diff
Git config part is installed with the plugin, but to be fully functional the following needs to be added to the ```.gitattributes``` file in the root directory of a charts repo:
```
secrets.yaml diff=sopsdiffer
secrets.*.yaml diff=sopsdiffer
```
More info on [sops page](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)

#### Using Helm plugin manager (> 2.3.x)

As already described above,
```
helm plugin install https://github.com/jkroepke/helm-secrets 
```

## Usage and examples

```
$ helm secrets help
GnuPG secrets encryption in Helm Charts

This plugin provides ability to encrypt/decrypt secrets files
to store in less secure places, before they are installed using
Helm.

To decrypt/encrypt/edit you need to initialize/first encrypt secrets with
sops - https://github.com/mozilla/sops

Available Commands:
  enc     Encrypt secrets file
  dec     Decrypt secrets file
  view    Print secrets decrypted
  edit    Edit secrets file and encrypt afterwards
  clean   Remove all decrypted files in specified directory (recursively)
  <cmd>   wrapper that decrypts secrets[.*].yaml files before running helm <cmd>
```

By convention, files containing secrets are named `secrets.yaml`, or anything beginning with "secrets." and ending with ".yaml". E.g. `secrets.test.yaml` and `secrets.prod.yaml`.

Decrypted files have the suffix ".yaml.dec" by default. This can be changed using the `HELM_SECRETS_DEC_SUFFIX` environment variable.

#### Basic commands:
```
  enc           Encrypt secrets file
  dec           Decrypt secrets file
  view          Print decrypted secrets file
  edit          Edit secrets file (decrypt before and encrypt after)
  clean         Delete *.yaml.dec files in directory (recursively)
```
Each of these commands have their own help.

## Use case and workflow

#### Usage examples

Note: You need to run `gpg --import example/pgp/project{x,y}.asc` in order to successfully decrypt secrets included in the examples

##### Decrypt

The decrypt operation decrypts a secrets.yaml file and saves the decrypted result in secrets.yaml.dec:
```
$ helm secrets dec example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Decrypting example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```

The secrets.yaml.dec file:
```
secret_sandbox_projectx: secret_foo_123
```

Note that if the secrets.yaml.dec file already exists and is newer than secrets.yaml, it will not be overwritten:
```
$ helm secrets dec example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Decrypting example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml.dec is newer than example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```

##### Encrypt

The encrypt operation encrypts a secrets.yaml.dec file and saves the encrypted result in secrets.yaml:

If you initially have an unencrypted secrets.yaml file, it will be used as input and will be overwritten:

```
$ helm secrets enc example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Encrypting example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Encrypted example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```

If you already have an encrypted secrets.yaml file and a decrypted secrets.yaml.dec file, encrypting will encrypt secrets.yaml.dec to secrets.yaml:
```
$ helm secrets dec example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Decrypting example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
$ helm secrets enc example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Encrypting example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Encrypted example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml.dec to example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```
##### View
The view operation decrypts secrets.yaml and prints it to stdout:
```
$ helm secrets view example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
secret_sandbox_projectx: secret_foo_123
```
##### Edit
The edit operation will decrypt the secrets.yaml file and open it in an editor. If the file is modified, it will be encrypted again after you exit the editor.

```
$ helm secrets edit example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```
There is new feature in SOPS master that allows using $EDITOR to spcify editor used by sops but not released yet.

##### Clean

The operation will delete all decrypted files in a directory, recursively:

```
$ helm secrets clean example/helm_vars/projectX/sandbox/us-east-1/java-app/
removed example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml.dec
```

If you use git there is commit hook that prevents commiting decrypted files and you can add all *.yaml.dec files in you repository ```.gitignore``` file.

#### Summary

* Values/Secrets data are not a part of the chart. You need to manage your values, public charts contains mostly defaults without secrets - data vs code
* To use the helm-secrets plugin you should build your ```.sops.yaml``` rules to make everything automatic
* Use helm secrets <enc|dec|view|edit> for everyday work with you secret yaml files
* Use version control systems like GIT to work in teams and get history of versions
* Everyday search keys is simple even with encrypted files or decrypt on-the-fly with git diff config included
* With example helm_vars you can manage multiple world locations with multiple projects that contain multiple environments
* With the helm wrapper you can easily run "helm secrets install/upgrade/rollback" with secrets files included as ```-f``` option from you helm_vars values dir tree.

We use vars for Helm Charts from separate directory tree with the structure like this:
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
As we use simple -f option when running the helm wrapper we can just use encrypted secrets.yaml and all these secrets will be decrypted and cleaned on the fly before and after helm run.

```.sops.yaml``` file example
```
---
creation_rules:
        # Encrypt with AWS KMS
        - kms: 'arn:aws:kms:us-east-1:222222222222:key/111b1c11-1c11-1fd1-aa11-a1c1a1sa1dsl1+arn:aws:iam::222222222222:role/helm_secrets'

        # Encrypt using GCP KMS
        - gcp_kms: projects/mygcproject/locations/global/keyRings/mykeyring/cryptoKeys/thekey

        # As failover encrypt with PGP
        - pgp: '000111122223333444AAAADDDDFFFFGGGG000999'

        # For more help look at https://github.com/mozilla/sops
```
Multiple KMS and PGP are allowed.

Everything is described in SOPS docs - links in this project description.

## Helm Wrapper

Running helm to install/upgrade chart with our secrets files is simple with the included helm wrapper which will decrypt on-the-fly and use decrypted secrets files in the actual helm command.

#### Wrapped commands
```
  install       run "helm install" with decrypted secrets files
  upgrade       run "helm upgrade" with decrypted secrets files
  lint          run "helm lint" with decrypted secrets files
  diff          run "helm diff" with decrypted secrets files
```

The wrapper enables you to call these helm commands with on-the-fly decryption of secrets files passed as `-f` or `--values` arguments. Instead of calling e.g. `helm install ...` you can call `helm secrets install ...` to get on-the-fly decryption.

The diff command is a separate helm plugin, [helm-diff](<https://github.com/databus23/helm-diff>). Using it you can view the changes that would be deployed before deploying. In the same way as above, instead of calling e.g. `helm diff upgrade ...` you can call `helm secrets diff upgrade ...`, and so on.

Note that if a decrypted secrets.yaml.dec file exists and is newer then the secrets.yaml file, it will be used in the wrapped command rather than decrypting secrets.yaml. 

Real example of the helm wrapper usage with simple java helloworld application.
```
AWS_PROFILE=sandbox helm secrets upgrade \
  helloworld \
  stable/java-app \
  --install \
  --timeout 600 \
  --wait \
  --kube-context=sandbox \
  --namespace=projectx \
  --set global.app_version=bff8fc4 \
  -f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml \
  -f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/values.yaml \
  -f helm_vars/secrets.yaml \
  -f helm_vars/values.yaml

Release "helloworld" has been upgraded. Happy Helming!
LAST DEPLOYED: Fri May  5 13:27:01 2017
NAMESPACE: projectx
STATUS: DEPLOYED

RESOURCES:
==> extensions/v1beta1/Deployment
NAME        DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
helloworld  3        3        3           2          1h

==> v1/Secret
NAME        TYPE    DATA  AGE
helloworld  Opaque  10    1h

==> v1/ConfigMap
NAME        DATA  AGE
helloworld  2     1h

==> v1/Service
NAME        CLUSTER-IP      EXTERNAL-IP  PORT(S)   AGE
helloworld  100.65.221.245  <none>       8080/TCP  1h

NOTES:
Deploy success helloworld-bff8fc4 in namespace projectx

removed helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml.dec
removed helm_vars/secrets.yaml.dec
```
You can see that we use a global secrets file and a specific secrets file for this app in this project/environment/region. We use some plain value files next to secrets. We use values from secrets in some secrets template in helloworld application chart template and some values are used in the configmap template in the same chart. Some values are added as env variables in deployment manifest templates in the chart. As you can see we can use secrets and values in helm in many ways. Everything depends on use case.

Even when helm failed then decrypted files are cleaned
```
AWS_PROFILE=sandbox helm-wrapper upgrade \
  helloworld \
  stable/java-app \
  --install \
  --timeout 600 \
  --wait \
  --kube-context=wrongcontext \
  --namespace=projectx \
  --set global.app_version=bff8fc4 \
  -f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml \
  -f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/values.yaml \
  -f helm_vars/secrets.yaml \
  -f helm_vars/values.yaml

Error: could not get kubernetes config for context 'wrongcontext': context "wrongcontext" does not exist

removed helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml.dec
removed helm_vars/secrets.yaml.dec
```
#### Using secret values in Helm chart secrets template

We just need to create Kubernetes secrets template in chart templates dir.
For example in your charts repo you have `stable/helloworld/`. Inside this chart you should have `stable/helloworld/templates/` dir and then create the `stable/helloworld/templates/secrets.yaml` file with content as specified bellow.

```
apiVersion: v1
kind: Secret
metadata:
  name: helloworld
  labels:
    app: helloworld
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
type: Opaque
data:
  my_secret_key: {{ .Values.secret_sandbox_helloworld | b64enc | quote }}
```

In this example you have a Kubernetes secret named "helloworld" and data inside this secret will be filled in from values defined in `-f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml`. We use `.Values.secret_sandbox_helloworld` to refer to the value in the decrypted secret file. In this way, the value from the decrypted `helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml` will be available as `my_secret_key` in Kubernetes.

You can now use the "helloworld" secret in your deployment manifest (or any other manifest supporting secretKeyRef) in the env section like this:
```
apiVersion: extensions/v1beta1
kind: Deployment
...
...
        containers:
        ...
        ...
          env:
            - name: my_new_secret_key
              valueFrom:
                secretKeyRef:
                  name: helloworld
                  key: my_secret_key
```
## Important Tips

#### Prevent committing decrypted files to git
If you like to secure situation when decrypted file is committed by mistake to git you can add your secrets.yaml.dec files to you charts project repository `.gitignore`.

A second level of security is to add for example a `.sopscommithook` file inside your chart repository local commit hook.

This will prevent committing decrypted files without sops metadata.

`.sopscommithook` content example:
```
#!/bin/sh

for FILE in $(git diff-index HEAD --name-only | grep <your vars dir> | grep "secrets.y"); do
    if [ -f "$FILE" ] && ! grep -C10000 "sops:" $FILE | grep -q "version:"; then
        echo "!!!!! $FILE" 'File is not encrypted !!!!!'
        echo "Run: helm secrets enc <file path>"
        exit 1
    fi
done
exit
```
