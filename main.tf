terraform {
  required_version = "~> 0.14"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.20.0"
    }

    local = {
      source = "hashicorp/local"
      version = "2.0.0"
    }

    null = {
      source = "hashicorp/null"
      version = "3.0.0"
    }

    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }

  backend "s3" {
    bucket = "terraform-eks-poc-infrastructure"
    key = "state.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.region
}
