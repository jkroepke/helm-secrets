# Usage and examples

```
$ helm secrets help

helm-secrets is a helm plugin for decrypt encrypted helm value files on the fly.

For more information, see the README.md at https://github.com/jkroepke/helm-secrets

To decrypt/encrypt/edit locally you need to initialize/first encrypt secrets with
sops - https://github.com/mozilla/sops

Available Commands:
  encrypt Encrypt secrets file
  decrypt Decrypt secrets file
  edit    Edit secrets file and encrypt afterwards
  dir     Get plugin directory
  patch   Enables windows specific adjustments
  <cmd>   wrapper that decrypts encrypted yaml files before running helm <cmd>

Available Options:
  --quiet                                          -q  Suppress info messages (env: $HELM_SECRETS_QUIET)
  --backend                                        -b  Secret backend to use for decryption or encryption (env: $HELM_SECRETS_BACKEND)
  --backend-args                                   -a  Additional args for secret backend (env: $HELM_SECRETS_BACKEND_ARGS)
  --ignore-missing-values [true|false]                 Ignore missing value files (env: $HELM_SECRETS_IGNORE_MISSING_VALUES)
  --evaluate-templates [true|false]                    Evaluate secret expressions inside helm template (only supported by vals backend) (env: $HELM_SECRETS_EVALUATE_TEMPLATES)
  --evaluate-templates-decode-secrets [true|false]     If --evaluate-templates is set, decode base64 values from secrets to evaluate them (env: $HELM_SECRETS_EVALUATE_TEMPLATES_DECODE_SECRETS)
  --help                                           -h  Show help
  --version                                        -v  Display version of helm-secrets
```

By convention, files containing secrets are named `secrets.yaml`, or anything beginning with "secrets" and ending with ".yaml". E.g. `secrets.test.yaml`, `secrets.prod.yaml` `secretsCOOL.yaml`.

**But unlike zendesk/helm-secrets, you can name your secret file as you want**

Decrypted files have the suffix ".dec" by default. This can be changed using the `HELM_SECRETS_DEC_SUFFIX` environment variable.

## Basic commands:

```
  encrypt Encrypt secrets file
  decrypt Decrypt secrets file
  edit    Edit secrets file and encrypt afterwards
```

Each of these commands have their own help.

# Use-case and workflow

## Usage examples

Note: You need to run `gpg --import tests/assets/gpg/private.gpg` in order to successfully decrypt secrets included in the examples

### Decrypt

The `decrypt` operation decrypts a secrets.yaml file:

```bash
helm secrets decrypt examples/sops/secrets.yaml
```

Output

```
podAnnotations:
    secret: value
```

Inline decryption is supported, too.

```
$ helm secrets decrypt -i examples/sops/secrets.yaml
```

### Encrypt

The `encrypt` operation encrypts a file and output the encrypted file:

```
$ helm secrets encrypt examples/sops/secrets.yaml
```

Inline encryption is supported, too.

```
$ helm secrets decrypt -i examples/sops/secrets.yaml
```

### Edit

The edit operation will decrypt the secrets.yaml file and open it in an editor. If the file is modified, it will be encrypted again after you exit the editor.

```
$ helm secrets edit examples/sops/secrets.yaml
```

There is new feature in SOPS master that allows using \$EDITOR to spcify editor used by sops but not released yet.

### Clean

The operation will delete all decrypted files in a directory, recursively:

```
$ helm secrets clean examples/sops/
removed examples/sops/secrets.yaml.dec
```

If you use git there is commit hook that prevents commiting decrypted files and you can add all \*.yaml.dec files in you repository `.gitignore` file.

### Summary

- Values/Secrets data are not a part of the chart. You need to manage your values, public charts contains mostly defaults without secrets - data vs code
- To use the helm-secrets plugin you should build your `.sops.yaml` rules to make everything automatic
- Use helm secrets <enc|dec|view|edit> for everyday work with you secret yaml files
- Use version control systems like GIT to work in teams and get history of versions
- Everyday search keys is simple even with encrypted files or decrypt on-the-fly with git diff config included
- With example helm_vars you can manage multiple world locations with multiple projects that contain multiple environments
- With the helm wrapper you can easily run "helm secrets install/upgrade/rollback" with secrets files included as `-f` option from you helm_vars values dir tree.

We use vars for Helm Charts from separate directory tree with the structure like this:

```
charts/
├── .sops.yaml
└── projectX
    ├── .sops.yaml
    ├── stages
    │   ├── dev
    │   │   ├── secrets.yaml
    │   │   └── env.yaml
    │   └── test
    │       ├── secrets.yaml
    │       └── env.yaml
    ├── secrets.yaml
    └── values.yaml
```

As you can see we can run different PGP or KMS keys per project, globally or per any tree level. Thanks to this we can isolate tree on different CI/CD instances using same GIT repository.
As we use simple -f option when running the helm wrapper we can just use encrypted secrets.yaml and all these secrets will be decrypted and cleaned on the fly before and after helm run.

`.sops.yaml` file example

```yaml
---
creation_rules:
# Encrypt with AWS KMS
- kms: 'arn:aws:kms:us-east-1:222222222222:key/111b1c11-1c11-1fd1-aa11-a1c1a1sa1dsl1+arn:aws:iam::222222222222:role/helm_secrets'

# Encrypt using GCP KMS
- gcp_kms: projects/mygcproject/locations/global/keyRings/mykeyring/cryptoKeys/thekey

# As failover encrypt with PGP (obtan via gpg --list-secret-keys)
- pgp: '000111122223333444AAAADDDDFFFFGGGG000999'

```
For more help look at https://github.com/mozilla/sops

Multiple KMS and PGP are allowed.

Everything is described in SOPS docs - links in this project description.

## Helm Wrapper

Running helm to install/upgrade chart with our secrets files is simple with the included helm wrapper which will decrypt on-the-fly and use decrypted secrets files in the actual helm command.

The wrapper enables you to call these helm commands with on-the-fly decryption of secrets files passed as `-f` or `--values` arguments. Instead of calling e.g. `helm install ...` you can call `helm secrets install ...` to get on-the-fly decryption.

The diff command is a separate helm plugin, [helm-diff](https://github.com/databus23/helm-diff). Using it you can decrypt the changes that would be deployed before deploying. In the same way as above, instead of calling e.g. `helm diff upgrade ...` you can call `helm secrets diff upgrade ...`, and so on.

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

### Using secret values in Helm chart secrets template

We just need to create Kubernetes secrets template in chart templates dir.
For example in your charts, repo you have `stable/helloworld/`. Inside this chart you should have `stable/helloworld/templates/` dir and then create the `stable/helloworld/templates/secrets.yaml` file with content as specified bellow.

```yaml
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

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
        - name: container
          env:
          - name: my_new_secret_key
            valueFrom:
              secretKeyRef:
                name: helloworld
                key: my_secret_key
```

## Alternative: decrypt via downloader plugin

Helm supports [downloader plugin](https://helm.sh/docs/topics/plugins/#downloader-plugins) for value files, too.

```bash
helm upgrade . -f 'secrets://<uri to file>'
```

Example:
```bash
helm upgrade . -f 'secrets://localfile.yaml'
helm upgrade . -f 'secrets://git+https://github.com/jkroepke/helm-secrets@tests/assets/values/sops/secrets.yaml?ref=main'
```

See also: https://github.com/jkroepke/helm-secrets/wiki/Values

### Load a gpg/age key on-demand

To assist the CD pipeline in certain situations (e.g. ArgoCD), helm-secret can load the gpg key from disk into a temporary gpg agent.

```bash
helm upgrade . -f 'secrets+gpg-import://<uri to gpg key>?<uri to file>'
helm upgrade . -f 'secrets+age-import://<uri to age key txt>?<uri to file>'
```
Example:

```bash
helm upgrade . -f 'secrets+gpg-import://tests/assets/gpg/private.gpg?examples/sops/secrets.yaml'
helm upgrade . -f 'secrets+age-import://tests/assets/age/keys.txt?examples/sops/secrets.yaml'
```

Support kubernetes secrets as source is possible, too:

```bash
helm upgrade . -f 'secrets+gpg-import-kubernetes://[<namespace>]/<name>#<key>?<uri to file>'
helm upgrade . -f 'secrets+age-import-kubernetes://[<namespace>]/<name>#<key>?<uri to file>'
```
Example:

```bash
helm upgrade . -f 'secrets+gpg-import-kubernetes://default/gpg-key#examples/sops/secrets.yaml'
helm upgrade . -f 'secrets+age-import-kubernetes://default/age-key.txt#examples/sops/secrets.yaml'
```

### --set / --set-file

```bash
helm upgrade . --set-file 'mysql=secrets://secrets.yaml'
helm upgrade . --set-file 'mysql.rootPassword=secrets+literal://ref+vault://secret/mysql#/rootPassword'

# --set requires helm secrets upgrade call
helm secrets upgrade . --set 'mysql=secrets://secrets.yaml'
```


## Evaluate secret reference inside helm template

*requires helm 3.9+; vals 0.20+*

helm secrets supports evaluating [vals](https://github.com/variantdev/vals) expressions inside helm templates by
enable the flag `--evaluate-templates`.

### Example

**secrets.yaml**

```yaml
apiVersion: v1
kind: Secret
stringData:
  password: "ref+awsssm://foo/bar?mode=singleparam#/BAR"
```

**Run**
```bash
helm secrets --evaluate-templates upgrade name .
```
