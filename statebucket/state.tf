provider "aws" {
  region = "us-east-1"
}


terraform {
  backend "s3" {
    bucket = "terraform_state_bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
