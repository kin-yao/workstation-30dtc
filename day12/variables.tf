variable "cluster_name" {
  type    = string
  default = "day12-cluster"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "server_port" {
  type    = number
  default = 80
}

variable "app_version" {
  type    = string
  default = "v1"
}