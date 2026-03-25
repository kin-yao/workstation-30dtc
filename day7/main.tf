terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "day6-terraform-state-711387095761"
    key            = "day7/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
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
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

variable "instance_type" {
  description = "EC2 instance type per environment"
  type        = map(string)
  default = {
    dev        = "t3.micro"
    staging    = "t3.small"
    production = "t3.medium"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type[terraform.workspace]

  tags = {
    Name        = "web-${terraform.workspace}"
    Environment = terraform.workspace
    Day         = "7"
  }
}

output "instance_id" {
  value = aws_instance.web.id
}

output "environment" {
  value = terraform.workspace
}

output "instance_type_used" {
  value = var.instance_type[terraform.workspace]
}