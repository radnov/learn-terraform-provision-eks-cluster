# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  /* Latest change from upstream repo
  https://github.com/hashicorp/learn-terraform-provision-eks-cluster/commit/d2e8d30f5bfe31f068322a544e07f3512c3b0e07

  token = data.aws_eks_cluster_auth.cluster.token
  */
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  /* This "old" way of authentication works with a named profile
  TODO: Update to "new" way of authentication from upstream repo once issue is resolved
  */
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name,
      "--profile",
      var.profile
    ]
  }
}
