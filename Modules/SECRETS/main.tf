resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.environment}-${var.project}-db-credentials"
  description = "Database credentials for RDS instance"
  recovery_window_in_days = var.recovery_window_in_days

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "${var.environment}-${var.project}-db-credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username 
    password = var.db_password
    engine= var.db_engine
    host = var.db_host
    port = var.db_port
    dbname = var.db_name
  })
  
}



