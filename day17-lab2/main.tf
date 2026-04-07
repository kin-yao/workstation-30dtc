terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "day6-terraform-state-711387095761"
    key    = "day17/lab2/terraform.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "imported" {
  bucket = "day17-import-test-711387095761"

  tags = {
    Name      = "day17-import-test"
    ManagedBy = "terraform"
    Day       = "17"
  }
}