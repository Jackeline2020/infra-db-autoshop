output "endpoint" {
  value = aws_db_instance.this.address
}

output "password" {
  value     = random_password.db.result
  sensitive = true
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}
