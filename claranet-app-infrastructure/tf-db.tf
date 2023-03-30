data "aws_secretsmanager_random_password" "db_pwd" {
  password_length = 20
  exclude_punctuation = true
}

resource "aws_secretsmanager_secret" "db_pwd_secret" {
  name = "db-master-pwd"
}

resource "aws_secretsmanager_secret_version" "db_pwd_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_pwd_secret.id
  secret_string = data.aws_secretsmanager_random_password.db_pwd.random_password
}

resource "aws_security_group" "db_sg" {
  name = var.db_sg_name
  description = var.alb_sg_desc
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private_subnet[*].cidr_block
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_docdb_subnet_group" "db_subnet_grp" {
  name       = var.db_subnet_grp_name
  subnet_ids = aws_subnet.private_subnet[*].id
}


resource "aws_docdb_cluster_instance" "db" {
  identifier            = var.db_instance_id
  cluster_identifier    = aws_docdb_cluster.db_cluster.id
  instance_class        = "db.t4g.medium"
  engine                 = "docdb"
  availability_zone      = "eu-central-1a"
}

resource "aws_docdb_cluster" "db_cluster" {
  cluster_identifier       = var.db_cluster_id
  master_username          = var.master_dba
  master_password          = aws_secretsmanager_secret_version.db_pwd_secret_version.secret_string
  engine                   = "docdb"
  engine_version           = "5.0.0"
  storage_encrypted        = true
  backup_retention_period  = 7
  preferred_backup_window  = "20:00-22:00"
  skip_final_snapshot      = true
  db_subnet_group_name     = aws_docdb_subnet_group.db_subnet_grp.name
  db_cluster_parameter_group_name = "default.docdb5.0"
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
}
