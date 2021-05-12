
variable "cluster" {}
variable "namespace" {}

locals {
  name = "${var.cluster}-${var.namespace}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "rbac" {
  name = local.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          // TODO: Is this enough? Is this only root or is this role assumable by all users in the account?
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })
}

resource "aws_iam_group_policy" "rbac" {
  name = local.name
  group = aws_iam_group.rbac.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAssumeOrganizationAccountRole"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Resource = aws_iam_role.rbac.arn
      },
    ]
  })
}

resource "aws_iam_group_policy" "cluster" {
  name = "${local.name}-cluster"
  group = aws_iam_group.rbac.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowEksDescribe"
        Action = "eks:DescribeCluster"
        Effect = "Allow"
        Resource = "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster}"
      },
    ]
  })
}

resource "aws_iam_group" "rbac" {
  name = local.name
}

output "role-arn" {
  value = aws_iam_role.rbac.arn
}

output "group-name" {
  value = aws_iam_group.rbac.name
}
