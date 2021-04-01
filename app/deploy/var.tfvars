vars {
aws_region  = "us-east-1"

image_id = "ami-042e8287309f5df03"

aws_network_cidr = "10.0.0.0/16"

aws_db_subnet_1_cidr  = "10.0.1.0/24"

aws_db_subnet_2_cidr  = "10.0.2.0/24"

aws_app_subnet_1_cidr = "10.0.3.0/24"

aws_app_subnet_2_cidr  = "10.0.4.0/24"

aws_pub_subnet_1_cidr = "10.0.5.0/24"

aws_pub_subnet_2_cidr = "10.0.6.0/24"

az_zone_1   = "us-east-1a"

az_zone_2   = "us-east-1b"

db_class    = "db.t2.micro"

db_user     = "app"

db_name     = "app"

db_engine   = "postgres"

db_engine_version = "10.7"

db_identifier = "app-db"
  }
