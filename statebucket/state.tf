provider "aws" {
  region = var.aws_region
}


terraform {
  backend "s3" {
    bucket = "terraform_state_bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
