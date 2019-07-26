data "aws_eks_cluster_auth" "cluster_auth" {
  name = "${aws_eks_cluster.this.id}"
}

provider "kubernetes" {
  host                   = "${aws_eks_cluster.this.endpoint}"
  cluster_ca_certificate = "${base64decode(aws_eks_cluster.this.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.cluster_auth.token}"
  load_config_file       = false
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

resource "null_resource" "wait_for_cluster" {
  
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = ["aws_eks_cluster.this"]

}

resource "kubernetes_config_map" "aws_auth_configmap" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

data {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.workers.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: ${lookup(var.map_roles[0], "role_arn")}
  username: ${lookup(var.map_roles[0], "username")}
  groups:
    - system:masters
YAML
  }
  depends_on = ["null_resource.wait_for_cluster"]
  }