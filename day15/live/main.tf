terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The root module owns the provider definitions.
# It passes them into the module via the providers map.

provider "aws" {
  alias  = "primary"
  region = "eu-north-1"
}

provider "aws" {
  alias  = "replica"
  region = "eu-west-1"
}

module "multi_region_app" {
  source   = "../modules/multi-region-app"
  app_name = "day15"

  # This wires the root module's providers to the aliases
  # the module declared in configuration_aliases.
  # Without this map, Terraform doesn't know which of the
  # root's providers should fill aws.primary and aws.replica.
  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}

output "primary_bucket" {
  value = module.multi_region_app.primary_bucket_name
}

output "replica_bucket" {
  value = module.multi_region_app.replica_bucket_name
}