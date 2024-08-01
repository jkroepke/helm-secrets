# Feature Flags

Some unstable or risky feature in helm-secrets are disabled by default.

# Environment variable expansion in URL value files

If the environment variable `HELM_SECRETS_URL_VARIABLE_EXPANSION` is set to `true`, then environment variables inside urls will be substituted.

## Example

- `secrets://https://${GITHUB_TOKEN}@raw.githubusercontent.com/org/repo/ref/pathtofile.yml`

In this case, `GITHUB_TOKEN` will be substituted with an environment variable named GITHUB_TOKEN. Only `${}` syntax is supported.

## Conflicting environments

Some environment like ArgoCD do the same, but with an [limited](https://argo-cd.readthedocs.io/en/stable/user-guide/build-environment/) subset of environment variables. 

In such situations, the `$` needs escaped to prevent evaluation in environments. For ArgoCD, it's an additional dollar sign like `$${GITHUB_TOKEN}`. Other environments are working with back-slash like `\${GITHUB_TOKEN}`
