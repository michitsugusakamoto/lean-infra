resource "aws_db_subnet_group" "default" {
  name       = "${var.name}-private"
  subnet_ids = var.private_subnet_ids
}

resource "aws_rds_cluster" "default" {
  cluster_identifier  = var.name
  engine              = "aurora-mysql"

  deletion_protection = false
  
  db_subnet_group_name = aws_db_subnet_group.default.name
  availability_zones   = var.availability_zones

  database_name   = var.db_name
  master_username = var.db_user
  master_password = var.db_password

  skip_final_snapshot = true
  
  apply_immediately = !var.is_production

  vpc_security_group_ids = [var.rds_sg]

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default.name

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

#resource "random_string" "ln" {
#  length  = 16
#  upper   = false
#  lower   = true
#  number  = true
#  special = false
#}

resource "aws_rds_cluster_instance" "default" {
  count = var.is_staging_and_staging_off ? 0 : var.is_production ? 1 : 1
  #identifier           = var.name
  #identifier           = "${var.name}-${random_string.ln.result}-${count.index}"
  identifier           = "${var.name}-take2-${count.index}"
  db_subnet_group_name = aws_db_subnet_group.default.name
  cluster_identifier   = aws_rds_cluster.default.id
  instance_class       = var.instance_class
  engine               = aws_rds_cluster.default.engine
  engine_version       = aws_rds_cluster.default.engine_version

  auto_minor_version_upgrade = false

  apply_immediately = !var.is_production
  #apply_immediately = false
}

resource "aws_rds_cluster_parameter_group" "default" {
  name   = var.name
  family = "aurora-mysql5.7"

  //japanese
  parameter {
    name         = "character_set_client"
    value        = "utf8mb4"
    apply_method = "immediate"
  }
  parameter {
    name         = "character_set_connection"
    value        = "utf8mb4"
    apply_method = "immediate"
  }
  parameter {
    name         = "character_set_database"
    value        = "utf8mb4"
    apply_method = "immediate"
  }
  parameter {
    name         = "character_set_results"
    value        = "utf8mb4"
    apply_method = "immediate"
  }
  parameter {
    name         = "character_set_server"
    value        = "utf8mb4"
    apply_method = "immediate"
  }
  parameter {
    name         = "time_zone"
    value        = "Asia/Tokyo"
    apply_method = "immediate"
  } 

  lifecycle {
    create_before_destroy = true
  }
}