locals {
  admin_role = [
    {
      rolearn = module.rbac-admin.role-arn
      username = "admin"
      groups = [
        "system:masters"
      ]
    }
  ]

  namespace_roles = [
    {
      rolearn = module.rbac-development.role-arn
      username = "development-user"
      groups = [
        module.rbac-development.group-name
      ]
    }
  ]

  map_roles = concat(local.admin_role, local.namespace_roles)
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name
  cluster_version = "1.19"
  subnets = module.vpc.private_subnets

  tags = {
    Environment = "training"
    GithubRepo = "terraform-aws-eks"
    GithubOrg = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  map_roles = local.map_roles

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name = "worker-group-1"
      instance_type = "t2.medium"
      additional_userdata = "echo foo bar"
      asg_desired_capacity = 2
      additional_security_group_ids = [
        aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name = "worker-group-2"
      instance_type = "t2.large"
      additional_userdata = "echo foo bar"
      additional_security_group_ids = [
        aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity = 1
    },
  ]
}

// TODO: This creates a dependency on our stack... But isn't there already a tight coupling between the cluster and the cluster stack?
resource "aws_security_group" "dummy" {
  name_prefix = "Dummy resource used by terraform to uninstall the nginx-ingress chart"
  vpc_id = module.vpc.vpc_id

  depends_on = [
    module.eks,
  ]

  provisioner "local-exec" {
    when = destroy
    command = "cd stacks/cluster && helmfile --selector name=ingress-nginx destroy"
  }
}

/* TODO: Bug! Should be reported... https://github.com/hashicorp/terraform-provider-random/issues
resource "random_string" "dummy" {
  length = 0

  depends_on = [
    module.eks,
  ]

  provisioner "local-exec" {
    when = destroy
    command = "helmfile --selector name=ingress-nginx destroy"
  }
}
*/

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
