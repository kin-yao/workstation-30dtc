terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "day6-terraform-state-711387095761"
    key            = "day13/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Step 1 — look up the secret metadata by name
data "aws_secretsmanager_secret" "db_credentials" {
  name = "prod/db/credentials"
}

# Step 2 — fetch the actual secret value using the secret's ID
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

# Step 3 — decode the JSON string into a map so we can reference
# individual keys. secret_string is a raw JSON string at this point
locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}

# Security group — RDS needs one even in the default VPC
resource "aws_security_group" "db_sg" {
  name        = "day13-db-sg"
  description = "MySQL access for day13 lab"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "day13-db-sg"
    Day  = "13"
  }
}

# RDS instance — credentials come from Secrets Manager at runtime
# search this entire file for the word "password" — you will not find it
resource "aws_db_instance" "example" {
  identifier        = "day13-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  db_name           = "appdb"
  allocated_storage = 10

  username = local.db_credentials["username"]
  password = local.db_credentials["password"]

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = "day13-db"
    Day  = "13"
  }
}