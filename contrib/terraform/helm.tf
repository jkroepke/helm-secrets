data "external" "helm-secrets" {
  program = ["helm", "secrets", "terraform", "../../examples/sops/secrets.yaml"]
}

resource "helm_release" "example" {
  name  = "helm-values-getter"
  chart = "../../examples/sops/"

  values = [
    file("../../examples/sops/values.yaml"),
    base64decode(data.external.helm-secrets.result.content_base64),
  ]
}
