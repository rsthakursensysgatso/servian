provider "aws" {
    region = var.aws_region
}



resource "aws_s3_bucket" "terraform-state" {
  bucket = "terraform_state_bucket"
  acl    = "private"
  force_destroy = true
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name        = "Terraform State"
  }
}
