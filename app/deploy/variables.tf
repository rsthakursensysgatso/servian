variable "aws_region" {
    default = "us-east-1"
}

variable "image_id" {
  description = "Image id"
  default = "ami-042e8287309f5df03"
}

variable "aws_network_cidr" {
    description = "Network CIDR"
    default = "10.0.0.0/16"
}

variable "aws_db_subnet_1_cidr" {
    description = "RDS Private CIDR"
    default = "10.0.1.0/24"
}


variable "aws_db_subnet_2_cidr" {
    description = "RDS Private CIDR"
    default = "10.0.2.0/24"
}

variable "aws_app_subnet_1_cidr" {
    description = "App Private CIDR"
    default = "10.0.3.0/24"
}

variable "aws_app_subnet_2_cidr" {
    description = "App Private CIDR"
    default = "10.0.4.0/24"
}


variable "aws_pub_subnet_1_cidr" {
    description = "Public CIDR"
    default = "10.0.5.0/24"
}

variable "aws_pub_subnet_2_cidr" {
    description = "Public CIDR"
    default = "10.0.6.0/24"
}

variable "az_zone_1" {
   description = "Availability Zone"
   default = "us-east-1a"
}

variable "az_zone_2" {
  description = "Availability Zone"
  default = "us-east-1b"
}


variable "db_class" {
  description = "Instance Type"
  default = "db.t2.micro"
}

variable "db_user" {
 description = "Database user"
 default = "app"
}

variable "db_name" {
 description = "Database name"
 default = "app"
}

variable "db_engine" {
 description = "Database engine type"
 default = "postgres"
}

variable "db_engine_version" {
 description = "Database engine version"
 default = "10.7"
}

variable "db_identifier" {
 description = "Database Identifier"
 default = "app-db"
}
