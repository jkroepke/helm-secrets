# Feature Flags

Some unstable or risky feature in helm-secrets are disabled by default.

# Environment variable expansion in URL value files

If the environment variable `HELM_SECRETS_URL_VARIABLE_EXPANSION` is set to `true`, then environment variables inside urls will be substituted.

## Example

- `secrets://https://${GITHUB_TOKEN}@raw.githubusercontent.com/org/repo/ref/pathtofile.yml`

In this case, `GITHUB_TOKEN` will be substituted with an environment variable named GITHUB_TOKEN. Only `${}` syntax is supported.
