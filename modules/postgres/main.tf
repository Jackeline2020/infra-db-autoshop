# Instância PostgreSQL (RDS) de um serviço, acessível só pelos nodes do
# cluster EKS. Usado pelas stacks os/ e billing/: cada serviço tem a própria
# instância, o próprio usuário e a própria senha.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "random_password" "db" {
  length  = 24
  special = false # evita caracteres que precisam de escape na connection string
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = data.aws_subnets.default.ids
  tags       = { Project = "autoshop", Service = var.name }
}

# Só os nodes do EKS falam com o banco, na porta 5432; sem acesso público
resource "aws_security_group" "db" {
  name        = "${var.name}-db-access"
  description = "Postgres (5432) only from EKS nodes"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "autoshop", Service = var.name }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-db"
  engine         = "postgres"
  engine_version = "16"

  instance_class         = var.instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  # Ambiente de estudo: sem snapshot final e sem proteção contra exclusão
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1

  tags = { Project = "autoshop", Service = var.name }
}

# Credenciais do serviço num segredo próprio. Sem janela de recuperação,
# para o mesmo nome poder ser recriado logo depois de um destroy.
resource "aws_secretsmanager_secret" "db" {
  name                    = "autoshop/${var.name}/db"
  recovery_window_in_days = 0
  tags                    = { Project = "autoshop", Service = var.name }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
    username = var.db_username
    password = random_password.db.result
  })
}
