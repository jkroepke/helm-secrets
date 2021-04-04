locals {
  # https://github.com/hashicorp/terraform/issues/15469
  # https://github.com/matti/terraform-shell-resource/issues/34
  is_error = length([for secret in module.secrets: secret.exitstatus if secret.exitstatus != "0"]) != length(local.secrets)
  throw_error = local.is_error ? file(join("\n", [for secret in module.secrets: secret.stderr if secret.stderr != ""])) : null
}

module "secrets" {
  for_each = toset(local.secrets)

  source = "matti/resource/shell"

  command     = "helm secrets view '${each.value}'"
  trigger     = filebase64sha256(each.value)
}

resource "helm_release" "chart-vault" {
  name  = "helm-values-getter"
  chart = "../../scripts/lib/file/helm-values-getter"

  values = concat(
    [for value in local.values: file(value)],
    [for secret in module.secrets: secret.stdout],
  )
}
