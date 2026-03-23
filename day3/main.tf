terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }   
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "web_sg"
    }
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello, World!" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web_instance"
    Project = "30-day-terraform-challenge"
    Day = "3"
  }
}

output "server_public_ip" {
    description = "Public ip of the web server"
    value = aws_instance.web_server.public_ip
  
}

output "website_url" {
    description = "URL of the website hosted on the web server"
    value = "http://${aws_instance.web_server.public_ip}"
  
}
