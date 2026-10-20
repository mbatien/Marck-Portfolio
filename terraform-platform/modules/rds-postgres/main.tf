# PostgreSQL on RDS in the private data subnets.
# The master password is created and rotated by RDS in Secrets Manager - it never appears in code or state.

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.data_subnet_ids
  tags       = { Name = var.name }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "PostgreSQL from the app only"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-db" }
}

# count (not for_each) because the security group IDs are usually unknown until apply.
resource "aws_vpc_security_group_ingress_rule" "from_app" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from an allowed app security group"
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name                             = var.db_name
  username                            = var.master_username
  manage_master_user_password         = true # password generated and stored in Secrets Manager
  iam_database_authentication_enabled = true

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage # storage autoscaling
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period   = var.backup_retention_days
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final"

  auto_minor_version_upgrade      = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = var.performance_insights_enabled
  apply_immediately               = var.apply_immediately
}

# Renamed resources: these blocks tell Terraform to rename them in state
# instead of destroying and recreating them. Safe to delete once every
# environment has been applied with the new names.
moved {
  from = aws_db_subnet_group.sg
  to   = aws_db_subnet_group.this
}

moved {
  from = aws_db_instance.db-instance
  to   = aws_db_instance.this
}
