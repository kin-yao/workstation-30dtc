# webserver-cluster module

Deploys an Auto Scaling Group of EC2 instances behind an Application Load Balancer.

## Usage
```hcl
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-dev"
  instance_type = "t3.micro"
  min_size      = 2
  max_size      = 4
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| cluster_name | Name prefix for all resources | string | yes |
| instance_type | EC2 instance type | string | no (default: t3.micro) |
| min_size | Minimum ASG instances | number | yes |
| max_size | Maximum ASG instances | number | yes |
| server_port | HTTP port on instances | number | no (default: 8080) |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | DNS name to hit the cluster |
| asg_name | Name of the Auto Scaling Group |
| alb_security_group_id | ALB security group ID |