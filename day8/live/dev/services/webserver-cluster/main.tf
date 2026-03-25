terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "day6-terraform-state-711387095761"
    key            = "day8/dev/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-dev"
  instance_type = "t3.micro"
  min_size      = 2
  max_size      = 4
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}

output "asg_name" {
  value = module.webserver_cluster.asg_name
}