module "rbac-admin" {
  source = "./modules/rbac"
  cluster = local.cluster_name
  namespace = "admin"
}

output "admin-role-arn" {
  value = module.rbac-admin.role-arn
}

output "admin-group-name" {
  value = module.rbac-admin.group-name
}

module "rbac-development" {
  source = "./modules/rbac"
  cluster = local.cluster_name
  namespace = "development"
}

output "development-role-arn" {
  value = module.rbac-development.role-arn
}

output "development-group-name" {
  value = module.rbac-development.group-name
}
