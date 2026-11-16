variable "name" {
  description = "Nome do serviço dono do banco (ex.: os, billing)"
  type        = string
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_username" {
  description = "Usuário do banco (a senha é gerada aleatoriamente)"
  type        = string
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "eks_node_security_group_id" {
  description = "Security group dos nodes do EKS (output eks_node_security_group_id do infra-k8s-autoshop)"
  type        = string
}
