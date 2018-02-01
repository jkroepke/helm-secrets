
[![License](https://img.shields.io/github/license/futuresimple/helm-secrets.svg)](https://github.com/futuresimple/helm-secrets/blob/master/LICENSE)
[![Current Release](https://img.shields.io/github/release/futuresimple/helm-secrets.svg)](https://github.com/futuresimple/helm-secrets/releases/latest)
[![Production Ready](https://img.shields.io/badge/production-ready-green.svg)](https://github.com/futuresimple/helm-secrets/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/futuresimple/helm-secrets.svg)](https://github.com/futuresimple/helm-secrets/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/futuresimple/helm-secrets.svg?style=flat-square)](https://github.com/futuresimple/helm-secrets/pulls)

# Plugin for secrets management in Helm

Developed and used in all environments in [BaseCRM](https://getbase.com/).

# how we use it ?

We store secrets and values in ```helm_vars``` dir structure just like in this repository example dir. All this data versioned in GIT.
Working in teams on multiple projects/regions/envs and multiple secrets files at once.
We have Makefile in our Helm charts repo to simplify install helm-secrets plugin with helm and other stuff we use. Same Makefile used to rebuild all helm charts with dependencies and some other everyday helpers.
Encrypting, Decrypting, Editing secrets on local clones, making #PR's and storing this in our helm charts repo encrypted with PGP and AWS KMS.
Deploying using helm-wrapper from local or from CI with same charts and secrets/values from GIT repository.

# Main features

A first internal version of the plugin used pure PGP and the whole secret file was encrypted as one.
A current version of the plugin using Golang sops as backend which could be integrated in future into Helm itself, but currently, it is only shell wrapper.

What kind of problems this plugin solves:
* Simple replaceable layer integrated with helm command for encrypting, decrypting, view secrets files stored in any place. Currently using SOPS as backend.
* [Support for YAML/JSON structures encryption - Helm YAML secrets files](https://github.com/mozilla/sops#important-information-on-types)
* [Encryption per value where visual Diff should work even on encrypted files](https://github.com/mozilla/sops/blob/master/example.yaml)
* [On the fly decryption for git diff](https://github.com/mozilla/sops#showing-diffs-in-cleartext-in-git)
* On the fly decryption and cleanup for helm install/upgrade with this plugin helm bash command wrapper
* [Multiple key management solutions like PGP and AWS KMS at same time](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
* [Simple adding/removing keys](https://github.com/mozilla/sops#adding-and-removing-keys)
* [With AWS KMS permissions management for keys](https://aws.amazon.com/kms/)
* [Secrets files directory tree separation with recursive .sops.yaml files search](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
* [Extracting sub-elements from encrypted file structure](https://github.com/mozilla/sops#extract-a-sub-part-of-a-document-tree)
* [Encrypt only part of a file if needed](https://github.com/mozilla/sops#encrypting-only-parts-of-a-file). [Example encrypted file](https://github.com/mozilla/sops/blob/master/example.yaml)

## Moving parts of project

```helm-wrapper``` - It is not a part of Helm project itself. It is the just simple wrapper in the shell that runs helm bellow but wrapping secrets decryption and cleaning on-the-fly, before and after Helm run. Created from install-binary.sh in helm-secrets plugin install process as hook action making the symlink to wrapper.sh. This should be used as default command to operate with Helm client with helm-secrets installed.

```test.sh``` - Test script to check if all parts of the plugin work. Using example dir with vars structure and PGP keys to make real tests on real data with real encryption/decryption.

```install-binary.sh``` - Script used as the hook to install helm-wrapper, download and install sops and install git diff configuration for helm-secret files.

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
By default helm-wrapper is not configured to encrypt/decrypt secrets.yaml in charts templates. They are templates and values from specific secrets/value files should e used in this templates as reference from helm itself.
Set you own options as ENV variables if you like overwrite default kms enabled and decrypt charts disabled.
```
DECRYPT_CHARTS=false helm-wrapper ....
```
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

## Use case and workflow

#### Usage examples

Note: You need to run `gpg --import example/pgp/project{x,y}.asc` in order to successfully decrypt secrets included in the examples

##### Decrypt
```
$ helm secrets dec example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Decrypting example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```
As the output you will get example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml.dec with decrypted secrets inside
```
secret_sandbox_projectx: secret_foo_123
```
##### Encrypt
Decrypt
```
$ helm secrets dec example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Decrypting example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```
Now encrypt
```
$ helm secrets enc example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Encrypting example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
Encrypted example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```
##### View
With this option you will get decrypted file on stdout
```
$ helm secrets view example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
secret_sandbox_projectx: secret_foo_123
```
##### Edit
Currently will open vim with decrypted data from secret and on save will encrypt file with new edited data. If you quit without any modification no changes will be saved.
```
$ helm secrets edit example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml
```
There is new feature in SOPS master that allows using $EDITOR to spcify editor used by sops but not released yet.

##### Clean

Now clean dec file after manual decrypt
```
$ helm secrets clean example/helm_vars/projectX/sandbox/us-east-1/java-app/
example/helm_vars/projectX/sandbox/us-east-1/java-app/secrets.yaml.dec
```
If you use git there is commit hook that prevents commiting decrypted files and youo can add all *.dec files in you charts project ```.gitignore``` file.

#### Summary

* Values/Secrets data are not a part of the chart. You need to manage your values, public charts contains mostly defaults without secrets - data vs code
* To use the helm-secrets plugin you should build your ```.sops.yaml``` rules to make everything automatic
* Use helm secrets <enc|dec|view|edit> to everyday work with you secret yaml files
* Use version control systems like GIT to work in teams and get history of versions
* Everyday search keys is simple even with encrypted files or decrypt on-the-fly with git diff config included
* With example helm_vars you can manage multiple world locations with multiple projects that contain multiple environments
* With helm-wrapper you can easily run helm install/upgrade/rollback with secrets files included as ```-f``` option from you helm_vars values dir tree.

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
As we use simple -f option when running helm-wrapper we can just use encrypted secrets.yaml and all these secrets will be decrypted and cleaned on the fly before and after helm run.

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

## Helm Wrapper

Running helm to install/upgrade chart with our secret files is simple with helm-wrapper which will decrypt on-the-fly and use decrypted secret files specified by us.
Real example of helm-wrapper usage with simple java helloworld application.
```
AWS_PROFILE=sandbox helm-wrapper upgrade --install --timeout 600 --wait helloworld stable/java-app --kube-context=sandbox --namespace=projectx --set global.app_version=bff8fc4 -f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml -f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/values.yaml -f helm_vars/secrets.yaml -f helm_vars/values.yaml
>>>>>> Decrypt
Decrypting helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml
>>>>>> Decrypt
Decrypting helm_vars/secrets.yaml

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

>>>>>> Cleanup
helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml.dec
helm_vars/secrets.yaml.dec
```
You can see that we use global secret file and specific for this app in this project/environment/region secret. We use some plain value files next to secrets. We use values from secrets in some secrets template in helloworld application chart template and some values are used in the configmap template in the same chart. Some values are added as env variables in deployment manifest templates in the chart. As you can see we can use secrets and values in helm in many ways. Everything depends on use case.

Even when helm failed then decrypted files are cleaned
```
AWS_PROFILE=sandbox helm-wrapper upgrade --install --timeout 600 --wait helloworld stable/java-app --kube-context=wrongcontext --namespace=projectx --set global.app_version=bff8fc4 -f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml -f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/values.yaml -f helm_vars/secrets.yaml -f helm_vars/values.yaml
>>>>>> Decrypt
Decrypting helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml
>>>>>> Decrypt
Decrypting helm_vars/secrets.yaml

Error: could not get kubernetes config for context 'wrongcontext': context "wrongcontext" does not exist

>>>>>> Cleanup
helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml.dec
helm_vars/secrets.yaml.dec
```
#### Using secret values in Helm chart secrets template

We just need to create Kubenetes secrets template in chart templates dir.
For example in your charts repo you have ```stable/helloworld/``` inside this chart you should have ```stable/helloworld/templates/``` dir and then creating ```stable/helloworld/templates/secrets.yaml``` file with content as specified bellow.
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
In this example you will have Kubernetes secret created with name helloworld and data inside this secret will be filled from values defined in ```-f helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml```. Then we use plain ```.Values ``` pointing to key ```secret_sandbox_helloworld``` in decrypted secret file and value from this decrypted ```helm_vars/projectx/sandbox/us-east-1/java-app/helloworld/secrets.yaml``` will be available as ```my_secret_key``` in Kubernetes.

You can now call it in your deployment (or any other supporting secretKeyRef) manifest in env section like this:
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
