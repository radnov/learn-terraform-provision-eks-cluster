variable "region" {
  default = "eu-central-1"
  description = "AWS region"
}

variable "cluster_name" {
  default = "dhis-poc"
  description = "EKS Cluster name"
}

variable "namespace-users" {
  type = map(list(string))

  default = {
    admin = [
      "radoslav",
      "andreas"
    ],
    development = [
      "rbac",
      "phil"
    ]
  }
}
