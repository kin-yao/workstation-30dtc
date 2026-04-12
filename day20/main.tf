terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "webserver" {
  name        = "day20-webserver-sg"
  description = "Allow HTTP inbound"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "webserver" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webserver.id]

  user_data = <<-USERDATA
    #!/bin/bash
    echo "Hello from Day 20 - v1" > index.html
    nohup busybox httpd -f -p 8080 &
  USERDATA

  tags = {
    Name = "day20-webserver"
    Day  = "20"
  }
}

output "public_ip" {
  value       = aws_instance.webserver.public_ip
  description = "Public IP of the webserver"
}
