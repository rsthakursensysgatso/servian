# Terraform S3 backend to store state file
terraform {
  backend "s3" {
    bucket = "app-terraform-state-bucket"
    key    = "terraform.tfstate"
    region = "aws-region"
  }
}
