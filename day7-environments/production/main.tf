terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

locals {
  environment   = "production"
  instance_type = "t3.medium"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "web" {
  name        = "${local.environment}-day7-layout-sg"
  description = "Day 7 file layout sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.environment}-day7-layout-sg"
    Environment = local.environment
    Day         = "7"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = local.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name        = "${local.environment}-day7-layout"
    Environment = local.environment
    Day         = "7"
  }
}

output "instance_id"   { value = aws_instance.web.id }
output "environment"   { value = local.environment }
output "instance_type" { value = local.instance_type }