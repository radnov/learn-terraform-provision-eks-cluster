variable "region" {
  default = "eu-central-1"
  description = "AWS region"
}

variable "cluster_name" {
  default = "dhis-poc"
  description = "EKS Cluster name"
}

variable "profile" {
  default = "default"
  description = "AWS profile for authenticating with the cluster"
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
