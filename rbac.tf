module "rbac-namespace" {
  for_each = var.namespace-users

  source = "./modules/rbac"
  cluster = var.cluster_name
  namespace = each.key
  users = each.value
}

output "group-to-role-arns" {
  value = {for key in sort(keys(var.namespace-users)) : module.rbac-namespace[key].group-name => module.rbac-namespace[key].role-arn}
}

output "namespaces" {
  value = [for key in keys(var.namespace-users): key if key != "admin"]
}
