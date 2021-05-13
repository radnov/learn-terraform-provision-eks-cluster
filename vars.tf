variable "region" {
  default = "eu-central-1"
  description = "AWS region"
}

variable "cluster_name" {
  default = "dhis-poc"
  description = "EKS Cluster name"
}

variable "admin-users" {
  default = [
    "radoslav",
    "andreas"
  ]
}

variable "development-users" {
  default = [
    "rbac",
    "phil"
  ]
}
