resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-${var.project}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.environment}-${var.project}-db-subnet-group"
    Tier = "db"
  }

}


resource "aws_db_parameter_group" "db_parameter_group" {
  name        = "${var.environment}-${var.project}-db-pp"
  family      = "postgres15"
  description = "Custom parameter group for PostgreSQL"

  parameter {
    name = "log_connections"
    value = "1"
  }

  parameter {
    name = "log_disconnections"
    value = "1"
  }
  parameter {
    name = "log_duration"
    value = "1"
  }

  tags = {
    Name = "${var.environment}-${var.project}-db-pp"
    Tier = "db"
  }
  
}

resource "aws_db_instance" "db_instance" {
  identifier     = "${var.environment}-${var.project}-db-instance"
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = 5432

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.db_parameter_group.name
  publicly_accessible    = false

  multi_az          = var.multi_az
  availability_zone = var.multi_az ? null : var.availability_zone

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.environment}-${var.project}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enabled_cloudwatch_logs_exports = ["postgresql","upgrade"] # Enable PostgreSQL logs and upgrade logs
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval != "0" ? aws_iam_role.rds_monitoring[0].arn : null

  auto_minor_version_upgrade = true
  deletion_protection        = var.deletion_protection


  tags = {
    Name = "${var.environment}-${var.project}-db-instance"
    Tier = "db"
  }
}

resource "aws_iam_role" "rds_monitoring" {
 count = var.monitoring_interval != "0" ? 1 : 0
  name = "${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.environment}-rds-monitoring-role"
    Tier = "db"
  }
  
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attachment" {
  count = var.monitoring_interval != "0" ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  
}
