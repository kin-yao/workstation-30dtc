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

# --- Phase 1: ternary + locals ---

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "enable_monitoring" {
  description = "Create CloudWatch alarm for IAM activity"
  type        = bool
  default     = false
}

variable "enable_admin_group" {
  description = "Create an admin IAM group"
  type        = bool
  default     = false
}

locals {
  is_production    = var.environment == "production"
  user_count       = local.is_production ? 5 : 2
  path_prefix      = local.is_production ? "/prod/" : "/dev/"
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# --- Phase 2: for_each users driven by locals ---

resource "aws_iam_user" "app_users" {
  for_each = toset([
    for i in range(local.user_count) : "day11-${var.environment}-user-${i}"
  ])
  name = each.value
  path = local.path_prefix
  tags = local.tags
}

# --- Phase 3: count = bool ? 1 : 0 ---

resource "aws_iam_group" "admin" {
  count = var.enable_admin_group ? 1 : 0
  name  = "day11-${var.environment}-admins"
  path  = local.path_prefix
}

resource "aws_cloudwatch_metric_alarm" "iam_activity" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "day11-${var.environment}-iam-activity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EventCount"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "IAM activity detected in ${var.environment}"
}

# --- Outputs ---

output "user_arns" {
  value = { for name, user in aws_iam_user.app_users : name => user.arn }
}

output "admin_group_arn" {
  value = var.enable_admin_group ? aws_iam_group.admin[0].arn : null
}

output "alarm_arn" {
  value = var.enable_monitoring ? aws_cloudwatch_metric_alarm.iam_activity[0].arn : null
}

output "environment_summary" {
  value = {
    environment   = var.environment
    is_production = local.is_production
    user_count    = local.user_count
    path_prefix   = local.path_prefix
  }
}