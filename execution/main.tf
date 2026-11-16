# Tabelas DynamoDB do Execution Service (execution-autoshop). Stack
# independente: estado e apply próprios. As permissões de acesso ficam na
# role do pod do Execution (IRSA, no infra-k8s-autoshop).

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

locals {
  # tabela => chave de partição
  tables = {
    parts              = "part_id"
    reservations       = "order_id"
    executions         = "order_id"
    processed_messages = "message_id"
  }
}

resource "aws_dynamodb_table" "this" {
  for_each = local.tables

  name         = "autoshop-${each.key}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = each.value

  attribute {
    name = each.value
    type = "S"
  }

  # Mensagens processadas expiram sozinhas (campo expires_at, em 7 dias)
  dynamic "ttl" {
    for_each = each.key == "processed_messages" ? [1] : []
    content {
      attribute_name = "expires_at"
      enabled        = true
    }
  }

  tags = { Project = "autoshop", Service = "execution" }
}

output "table_names" {
  description = "Nomes das tabelas (variáveis PARTS_TABLE, RESERVATIONS_TABLE, EXECUTIONS_TABLE e PROCESSED_MESSAGES_TABLE do Execution)"
  value       = { for k, t in aws_dynamodb_table.this : k => t.name }
}
