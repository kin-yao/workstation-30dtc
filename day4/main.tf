terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region 
  
}

# to fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
    most_recent = true
    owners      = ["amazon"]
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

#dynamically fetch available AZ in the region
data "aws_availability_zones" "all" {}
  resource "aws_security_group" "web_sg" {
    name        = "${var.environment}-web-sg"
    description = "Allow HTTP traffic on port ${var.server_port}"

    ingress {
        description = "HTTP from anywhere"
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH from anywhere"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name          = "${var.environment}-web-sg"
      Environment   = var.environment
      Project       = var.project_name
    }
}

resource "aws_instance" "web_server" {
    ami           = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.web_sg.id]

    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "<h1>Day 4 - Terraform Challenge</h1>
                <p>Environment: ${var.environment}</p>
                <p>Instance Type: ${var.instance_type}</p>
                <p>Deployed by Terraform on $(hostname)</p>" > /var/www/html/index.html
                EOF

    tags = {
        Name          = "${var.environment}-web-server"
        Environment   = var.environment
        Project       = var.project_name
        }   

}
