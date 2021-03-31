provider "aws" {
  region = var.aws_region
}



terraform {
  backend "s3" {
    bucket = "app-terraform-state-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}



resource "aws_launch_configuration" "APP-LC-2" {
  name                 = "APP-LC-2"
  image_id             = var.image_id
  instance_type        = "t2.micro"
  iam_instance_profile = "cwdb_iam_profile"
  security_groups = data.aws_security_group.app_asg.id
  user_data       = file("userdata-asg.sh")
  lifecycle { create_before_destroy = true }
}
