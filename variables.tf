variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "db_name" {
  description = "Nome do banco de dados PostgreSQL"
  type        = string
  default     = "autoshop"
}

variable "db_username" {
  description = "Usuário administrador do RDS (a senha é gerada aleatoriamente, ver rds.tf)"
  type        = string
  default     = "autoshop"
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "eks_node_security_group_id" {
  description = "Security group dos nodes do EKS — output eks_node_security_group_id do repositório infra-k8s. Colar aqui depois do primeiro apply do infra-k8s."
  type        = string
}

variable "additional_db_ingress_security_group_ids" {
  description = "Security groups extras autorizados a falar com o RDS na porta 5432, além dos nodes do EKS. Usado pela Lambda de autenticação (repositório lambda-auth): depois do primeiro apply de lambda-auth/terraform, cole aqui o output lambda_security_group_id."
  type        = list(string)
  default     = []
}
