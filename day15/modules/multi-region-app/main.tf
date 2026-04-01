# Modules cannot define aliased providers themselves — if they did,
# every caller would get the same hardcoded region with no way to
# override it. Instead, the module declares which provider aliases
# it expects to receive via configuration_aliases, and the caller
# wires its own providers in.

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}

resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${var.app_name}-primary-711387095761"

  tags = { Name = "${var.app_name}-primary" }
}

resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "${var.app_name}-replica-711387095761"

  tags = { Name = "${var.app_name}-replica" }
}