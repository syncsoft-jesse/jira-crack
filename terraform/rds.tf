# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group for Jira RDS"
  subnet_ids  = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# RDS Parameter Group for PostgreSQL
resource "aws_db_parameter_group" "jira" {
  name        = "${var.project_name}-${var.environment}-pg-params"
  family      = "postgres15"
  description = "PostgreSQL parameter group for Jira"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-pg-params"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "jira" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine
  engine               = "postgres"
  engine_version       = "15"  # Auto-select latest 15.x
  instance_class       = var.db_instance_class
  parameter_group_name = aws_db_parameter_group.jira.name

  # Storage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = 5432

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Deletion Protection
  deletion_protection       = var.environment == "prod" ? true : false
  skip_final_snapshot       = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-${var.environment}-final-snapshot" : null

  # Performance Insights (disabled to save cost on small instances)
  performance_insights_enabled = false

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}
