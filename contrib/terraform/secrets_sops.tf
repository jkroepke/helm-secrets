data "sops_file" "secrets" {
  for_each = toset(local.secrets)

  source_file = each.value
  input_type = "yaml"
}

resource "helm_release" "chart-sops" {
  name  = "helm-values-getter"
  chart = "../../scripts/lib/file/helm-values-getter"

  values = concat(
    [for value in local.values: file(value)],
    [for secret in data.sops_file.secrets: secret.raw],
  )
}
