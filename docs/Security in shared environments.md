# Security in shared environments

By default, helm-secrets follow symlinks or accept relative paths for values. In shared environments like Jenkins or ArgoCD, is can be a problem. 
Users can use helm-secrets to gain access to other files outside their own build directory.

To restrict access to file outside the build directory, certain restrictions can be enabled to prevent illegal access to other files.

# Configurable restrictions

## Disable symlinks

Symlinks can be abused to gain access to file outside the directory. To prevent this, set the environment variable

```bash
HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false
```

to through an error, if a referenced value file is a symlink.

## Disable absolute paths for value files

Throw an error, if the path of the value file is an absolute path. To prevent this, set the environment variable

```bash
HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false
```

## Disable path traversal

A path traversal attack (also known as directory traversal) aims to access files and directories that are stored outside the web root folder.
By manipulating variables that reference files with “dot-dot-slash (../)” sequences and its variations or by using absolute file paths, it may be possible
to access arbitrary files and directories stored on file system including application source code or configuration and critical system files. 

To prevent this, set the environment variable

```bash
HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false
```

## Key Location prefix

The ArgoCD integration required to mount the gpg/age keys on a specific location. By default, helm-secrets accept all locations of a gpg key. To restrict
the locations of keys, set an environment variable

```bash
HELM_SECRETS_KEY_LOCATION_PREFIX=/secrets/
```

To allow only gpg/age keys from the path `/secrets/`. 

## Restrict secret backends

A secret backend can be selected per value file with the `backend!` prefix, for example `secrets://vals!secrets.yaml`.
In shared environments that prefix is controlled by whoever writes the Application manifest or the value file reference.

Out-of-tree backends are shell scripts that get sourced by helm-secrets. For that reason, a file path is only accepted
in the `backend!` prefix when it is listed explicitly in `HELM_SECRETS_ALLOWED_BACKENDS`. The `--backend` option and the
`HELM_SECRETS_BACKEND` environment variable still accept any path, because they are set by the operator.

To additionally restrict which in-tree backends can be selected, set the environment variable

```bash
HELM_SECRETS_ALLOWED_BACKENDS=sops,vals
```

Backends that are not listed are rejected, regardless of how they are selected.
