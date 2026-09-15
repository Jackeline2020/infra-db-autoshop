# Banco de dados gerenciado (RDS PostgreSQL) — substitui as tabelas DynamoDB da Fase 2.

resource "random_password" "db" {
  length  = 24
  special = false # evita caracteres que precisam de escape na connection string
}

resource "aws_db_subnet_group" "autoshop" {
  name       = "autoshop-db"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Project = "autoshop"
  }
}

# Só o cluster EKS (repositório infra-k8s) e origens explicitamente
# autorizadas (ex: a Lambda do repositório lambda-auth) podem falar com o
# banco na porta 5432, sem acesso público.
resource "aws_security_group" "db" {
  name        = "autoshop-db-access"
  description = "Allows Postgres traffic (5432) only from EKS nodes and explicitly authorized sources"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Postgres from EKS nodes and other authorized sources (ex: lambda-auth)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = concat([var.eks_node_security_group_id], var.additional_db_ingress_security_group_ids)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "autoshop"
  }
}

resource "aws_db_instance" "autoshop" {
  identifier     = "autoshop-db"
  engine         = "postgres"
  engine_version = "16"

  # menor instância disponível — dimensionado pra um projeto de estudo, não produção real
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp3"
  db_subnet_group_name    = aws_db_subnet_group.autoshop.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  # skip_final_snapshot = true porque isso é um projeto de estudo (Tech Challenge);
  # numa base real de produção, isso ficaria false + deletion_protection = true.
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1

  tags = {
    Project = "autoshop"
  }
}

# Credenciais completas de conexão num secret só — o pod (via IRSA, no
# infra-k8s) e a Lambda (via env var, no lambda-auth) leem isso em runtime,
# nada de senha em ConfigMap/imagem.
resource "aws_secretsmanager_secret" "db" {
  name = "autoshop/rds/credentials"

  tags = {
    Project = "autoshop"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = aws_db_instance.autoshop.address
    port     = aws_db_instance.autoshop.port
    dbname   = var.db_name
    username = var.db_username
    password = random_password.db.result
  })
}
