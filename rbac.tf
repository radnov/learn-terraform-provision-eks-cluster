module "rbac-admin" {
  source = "./modules/rbac"
  cluster = var.cluster_name
  namespace = "admin"
}

output "admin-role-arn" {
  value = module.rbac-admin.role-arn
}

output "admin-group-name" {
  value = module.rbac-admin.group-name
}

resource "aws_iam_group_membership" "admin-group-members" {
  name = "admin-group-membership"
  users = var.admin-users
  group = module.rbac-admin.group-name
}

// ======================================================================

module "rbac-development" {
  source = "./modules/rbac"
  cluster = var.cluster_name
  namespace = "development"
}

output "development-role-arn" {
  value = module.rbac-development.role-arn
}

output "development-group-name" {
  value = module.rbac-development.group-name
}

// ======================================================================

module "rbac-something" {
  source = "./modules/rbac"
  cluster = var.cluster_name
  namespace = "something"
}

output "something-role-arn" {
  value = module.rbac-something.role-arn
}

output "something-group-name" {
  value = module.rbac-something.group-name
}
