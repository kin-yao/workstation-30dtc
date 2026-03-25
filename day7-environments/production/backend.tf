terraform {
  backend "s3" {
    bucket         = "day6-terraform-state-711387095761"
    key            = "environments/production/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}