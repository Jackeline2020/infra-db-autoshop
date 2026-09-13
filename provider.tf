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

  # produção real, configurar um backend remoto (bucket S3) — mesmo padrão
  # (comentado) dos outros projetos Terraform deste sistema.
  # backend "s3" {
  #   bucket = "autoshop-terraform-state"
  #   key    = "infra-db/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# Redeclarado aqui porque antes do split isso vinha de infra/aws/network.tf,
# que ficou no repositório infra-k8s. São data sources (apenas consulta,
# não criam nada) — redeclarar não gera conflito nenhum.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
