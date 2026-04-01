# This is a completely different provider from AWS — it talks to
# your local Docker daemon instead of AWS APIs. This is what
# "multiple different providers" means in Terraform. Same HCL
# syntax, completely different plugin underneath.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "terraform-nginx"

  ports {
    internal = 80
    external = 8080
  }
}

output "container_name" {
  value = docker_container.nginx.name
}

output "container_url" {
  value = "http://localhost:8080"
}