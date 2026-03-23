variable "aws_region" {
    description = "The AWS region to deploy resources in."
    type        = string
    default     = "us-east-1"
  
}

variable "instance_type" {
    description = "The type of EC2 instance to use."
    type        = string
    default     = "t2.micro"
  
}

variable "server_port" {
    description = "The port on which the server will listen."
    type        = number
    default     = 80
  
}

variable "environment" {
    description = "The deployment environment (e.g., dev, staging, prod)."
    type        = string
    default     = "dev"
  
}

variable "project_name" {
    description = "The name of the project."
    type        = string
    default     = "30-day-terraform-challenge"
  
}
