variable "aws_region" {
  description = "AWS region"
  type = string
  default = "eu-north-1"
}  

variable "instance_type" {
    description = "EC2 instance type"
    type = string
    default = "t2.micro"
  
}

variable "server_port" {
    description = "Port for the web server"
    type = number
    default = 80
  
}

variable "alb_port" {
    description = "Port for the Application Load Balancer"
    type = number
    default = 80
  
}

variable "min_size" {
    description = "Minimum number of instances in the Auto Scaling group"
    type = number
    default = 1
  
}

variable "max_size" {
    description = "Maximum number of instances in the Auto Scaling group"
    type = number
    default = 3
  
}

variable "environment" {
    description = "Environment name (e.g., dev, staging, prod)"
    type = string
    default = "dev"
  
}