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

# --- Phase 1: count ---

variable "user_names" {
  description = "List of IAM usernames to create"
  type        = list(string)
  default     = ["alice", "bob", "charlie"]
}

resource "aws_iam_user" "count_example" {
  count = length(var.user_names)
  name  = "day10-count-${var.user_names[count.index]}"
}

output "count_user_arns" {
  value = aws_iam_user.count_example[*].arn
}

# --- Phase 2: for_each with a set ---

variable "user_names_set" {
  type    = set(string)
  default = ["dave", "eve", "frank"]
}

resource "aws_iam_user" "foreach_example" {
  for_each = var.user_names_set
  name     = "day10-foreach-${each.value}"
}

# --- Phase 2b: for_each with a map ---

variable "users" {
  type = map(object({
    department = string
    admin      = bool
  }))
  default = {
    grace = { department = "engineering", admin = true }
    henry = { department = "marketing",   admin = false }
  }
}

resource "aws_iam_user" "map_example" {
  for_each = var.users
  name     = "day10-map-${each.key}"

  tags = {
    Department = each.value.department
    Admin      = each.value.admin
  }
}

# --- Phase 3: for expressions ---

output "foreach_user_arns" {
  value = { for name, user in aws_iam_user.foreach_example : name => user.arn }
}

output "upper_usernames" {
  value = [for name in var.user_names_set : upper(name)]
}

output "admin_users" {
  value = [for name, attrs in var.users : name if attrs.admin == true]
}

# --- Phase 4: conditionals ---

variable "enable_extra_user" {
  description = "Toggle to create an optional extra IAM user"
  type        = bool
  default     = true
}

variable "environment" {
  type    = string
  default = "dev"
}

resource "aws_iam_user" "optional_user" {
  count = var.enable_extra_user ? 1 : 0
  name  = "day10-optional-user"
}

locals {
  instance_type = var.environment == "production" ? "t3.medium" : "t3.micro"
}

output "optional_user_created" {
  value = var.enable_extra_user ? "yes" : "no"
}

output "instance_type_would_be" {
  value = local.instance_type
}