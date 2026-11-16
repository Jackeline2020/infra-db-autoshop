# Banco PostgreSQL do OS Service (app-autoshop). Stack independente: estado e
# apply próprios, sem depender dos bancos dos outros serviços.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "db" {
  source = "../modules/postgres"

  name                       = "os"
  db_name                    = "autoshop"
  db_username                = "autoshop"
  eks_node_security_group_id = var.eks_node_security_group_id
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "eks_node_security_group_id" {
  description = "Security group dos nodes do EKS (output eks_node_security_group_id do infra-k8s-autoshop)"
  type        = string
}

output "db_host" {
  description = "Secret DB_HOST do repositório do serviço"
  value       = module.db.endpoint
}

output "db_password" {
  description = "Secret DB_PASSWORD do repositório do serviço (terraform output -raw db_password)"
  value       = module.db.password
  sensitive   = true
}

output "db_secret_arn" {
  value = module.db.secret_arn
}
