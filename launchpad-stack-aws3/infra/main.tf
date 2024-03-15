
resource "time_static" "now" {}

locals {
  kube_tags = {
    "kubernetes.io/cluster/${var.name}" = "owned"
  }
}

locals {

  // build some tags for all things
  tags = merge(
    { # excludes kube-specific tags
      "stack"   = var.name
      "created" = time_static.now.rfc3339
    },
    var.extra_tags,
    local.kube_tags,
  )

}
