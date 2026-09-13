output "rds_endpoint" {
  description = "Host:porta do RDS — vira o DB_HOST_PLACEHOLDER em k8s/overlays/aws/configmap.yaml (repositório infra-k8s) antes do deploy real"
  value       = aws_db_instance.autoshop.address
}

output "rds_secret_arn" {
  description = "ARN do segredo no Secrets Manager com host/usuário/senha do RDS. Colar na variável rds_secret_arn do repositório infra-k8s."
  value       = aws_secretsmanager_secret.db.arn
}
