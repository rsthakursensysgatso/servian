
variable "aws_region" {
    default = "us-east-1"
}

variable "image_id" {
  description = "Image id"
  default = "ami-042e8287309f5df03"
}

variable "aws_network_cidr" {
    default = "10.0.0.0/16"
}

variable "aws_db_subnet_1_cidr" {
    default = "10.0.1.0/24"
}


variable "aws_db_subnet_2_cidr" {
    default = "10.0.2.0/24"
}

variable "aws_app_subnet_1_cidr" {
    default = "10.0.3.0/24"
}

variable "aws_app_subnet_2_cidr" {
    default = "10.0.4.0/24"
}


variable "aws_pub_subnet_1_cidr" {

    default = "10.0.5.0/24"
}

variable "aws_pub_subnet_2_cidr" {

    default = "10.0.6.0/24"
}

variable "az_zone_1" {
   default = "us-east-1a"
}

variable "az_zone_2" {
  default = "us-east-1b"
}

variable "aws_wp_db_user" {
  default = "postgres"
}
