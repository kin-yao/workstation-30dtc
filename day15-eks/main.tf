terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# The Kubernetes provider can't be configured until the EKS cluster
# exists — it needs the cluster endpoint and CA certificate, which
# are only known after apply. The exec block runs aws eks get-token
# at runtime to authenticate rather than storing a static token.

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "eu-north-1"]
  }
}

# VPC for the cluster — EKS requires a VPC with private subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "day15-eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-north-1a", "eu-north-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# EKS cluster using the official community module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "day15-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.small"]
    }
  }

  tags = {
    Environment = "dev"
    Day         = "15"
  }
}

# Nginx deployment on the cluster
# This resource uses the Kubernetes provider, not AWS.
# Terraform manages both the AWS infrastructure and the
# Kubernetes workload in the same apply.

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx-deployment"
    labels = { app = "nginx" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "nginx" }
    }

    template {
      metadata {
        labels = { app = "nginx" }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [module.eks]
}