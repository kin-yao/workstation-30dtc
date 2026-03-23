variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the ASG"
  type        = string
  default     = "t2.micro"
}

variable "server_port" {
  description = "Port the web servers listen on"
  type        = number
  default     = 80
}

variable "alb_port" {
  description = "Port the ALB listens on"
  type        = number
  default     = 80
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 5
}

variable "environment" {
  description = "Environment name used for tagging"
  type        = string
  default     = "dev"
}