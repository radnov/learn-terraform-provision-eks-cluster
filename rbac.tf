// TODO: The format should probably be cluster-namespace since we'll have multiple clusters
variable "name" {
  default = "Access-to-the-development-namespace"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "development" {
  name = var.name
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

resource "aws_iam_group_policy" "development" {
  name = var.name
  group = aws_iam_group.development.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAssumeOrganizationAccountRole"
        Action = [
          "sts:AssumeRole",
        ]
        Effect = "Allow"
        Resource = aws_iam_role.development.arn
      },
    ]
  })
}

resource "aws_iam_group_policy" "cluster" {
  name = "${var.name}-cluster"
  group = aws_iam_group.development.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowEksDescribe"
        Action = [
          "eks:DescribeCluster",
        ]
        Effect = "Allow"
        // TODO: Limit to specific cluster?
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_group" "development" {
  name = var.name
}

output "role_arn" {
  value = aws_iam_role.development.arn
}
