provider "aws" {
  region = var.aws_region
}



terraform {
  backend "s3" {
    bucket = "app-terraform-state-bucket"
    key    = "terraform.tfstate"
    region = "aws-region"
  }
}




resource "aws_vpc" "app_vpc" {
  cidr_block           = var.aws_network_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Servian App VPC"
  }
}

# create igw
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "Servian APP VPC Internet Gateway"
}
}

# add dhcp options
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["AmazonProvidedDNS"]
}

# associate dhcp with vpc
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.app_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}



#### DATABASE SUBNETS
resource "aws_subnet" "db_subnet_1" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = var.aws_db_subnet_1_cidr
  tags = {
    Name = "DB subnet 1"
  }
  availability_zone = var.az_zone_1
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = var.aws_db_subnet_2_cidr
  tags = {
    Name = "DB subnet 2"
  }
  availability_zone = var.az_zone_2
}

### SECURITY GROUP
resource "aws_security_group" "db" {
  name   = "Database SG"
  vpc_id = aws_vpc.app_vpc.id

  # TCP access only from APP subnet at port 5432
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      var.aws_app_subnet_1_cidr, 
      var.aws_app_subnet_2_cidr 
    ]
  }

  # Egress to everyone
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
 Name = "Database Security Group"
}
}

###### Provision RDS Postgres Database
# Create DB subnet group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "app_db_subnet_group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
  tags = {
  Name  = "App DB"  
}
}

resource "random_password" "password" {
  length           = 16
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  override_special = "_%$"
}

resource "aws_ssm_parameter" "db_username" {
  name        = "dbusername"
  description = "DB Username"
  type        = "SecureString"
  value       =  var.db_user

  tags = {
    Name      = "APP DB"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "dbpassword"
  description = "DB Password "
  type        = "SecureString"
  value       = random_password.password.result

  tags = {
    Name = "APP DB"
  }
}


resource "aws_ssm_parameter" "db_name" {
  name        = "dbname"
  description = "DB Name"
  type        = "SecureString"
  value       = var.db_name

  tags = {
    Name = "App DB"
  }
}

resource "aws_ssm_parameter" "db_hostname" {
  depends_on  = [aws_db_instance.app_db]
  name        = "dbhostname"
  description = "DB Hostname"
  type        = "SecureString"
  value       = aws_db_instance.app_db.address

  tags = {
    Name = "APP DB"
  }
}



resource "aws_db_instance" "app_db" {
  identifier        = var.db_identifier
  instance_class    = var.db_class
  allocated_storage = 20
  engine            = var.db_engine
  name              = var.db_name
  password          = random_password.password.result
  /*  password = random_password.password.result */
  username               = var.db_user
  engine_version         = var.db_engine_version
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db.id]
  tags = {
   Name = "APP DB"

}
}


#Provision APP Subnet
resource "aws_subnet" "app_subnet_1" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = var.aws_app_subnet_1_cidr
  tags = {
    Name = "APP subnet"
  }
  availability_zone = var.az_zone_1
}


resource "aws_subnet" "app_subnet_2" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = var.aws_app_subnet_2_cidr
  tags = {
    Name = "APP subnet"
  }
  availability_zone = var.az_zone_2
}

# Route Table with NAT gateway
resource "aws_route_table" "app-subnet-routes" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "APP-subnet-routes-1"
  }
}

/*resource "aws_route_table" "wp-subnet-routes1" {
    vpc_id = aws_vpc.app_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat-gw1.id
    }

    tags = {
        Name = "APP-subnet-routes"
    }
}*/

# Route Table Association with APP subnet

resource "aws_route_table_association" "app-subnet1-routes" {
  subnet_id      = aws_subnet.app_subnet_1.id
  route_table_id = aws_route_table.app-subnet-routes.id
}

resource "aws_route_table_association" "app-subnet2-routes" {
  subnet_id      = aws_subnet.app_subnet_2.id
  route_table_id = aws_route_table.app-subnet-routes.id
}



### SECURITY GROUPS #########################

#Private access for APP subnet
resource "aws_security_group" "app" {
  name   = "APP Private SG"
  vpc_id = aws_vpc.app_vpc.id

  # http access from application load balancer
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "TCP"
    cidr_blocks = [var.aws_pub_subnet_1_cidr, var.aws_pub_subnet_2_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
  Name = "App-Priv-SG"
}
}

# Public Subnet Groups required by load balancer

resource "aws_subnet" "pub_subnet_1" {

  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = var.aws_pub_subnet_1_cidr
  tags = {
    Name = "public subnet"
  }
  availability_zone = var.az_zone_1
}

resource "aws_subnet" "pub_subnet_2" {

  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = var.aws_pub_subnet_2_cidr
  tags = {
    Name = "public subnet 2"
  }
  availability_zone = var.az_zone_2
}


# Route with internet gateway attached

resource "aws_route_table" "public-routes" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
 tags = {
   Name = "App public route table"
}
}

# Route table association with Public Subnet
resource "aws_route_table_association" "public-subnet-routes-1" {
  subnet_id      = aws_subnet.pub_subnet_1.id
  route_table_id = aws_route_table.public-routes.id
}

resource "aws_route_table_association" "public-subnet-routes-2" {
  subnet_id      = aws_subnet.pub_subnet_2.id
  route_table_id = aws_route_table.public-routes.id
}

# NAT Gateway configuration for private subnetss
resource "aws_eip" "nat-eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.app_igw", "aws_vpc_dhcp_options_association.dns_resolver"]
  tags = {
  Name = "Nat Gateway EIP"
}
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.pub_subnet_1.id
  depends_on    = ["aws_internet_gateway.app_igw"]
  tags = {
  Name = "Nat Gateway"
}
}

/* resource "aws_eip" "nat-eip1" {
  vpc      = true
  depends_on = ["aws_internet_gateway.app_igw", "aws_vpc_dhcp_options_association.dns_resolver"]
} */

/* resource "aws_nat_gateway" "nat-gw1" {
  allocation_id = aws_eip.nat-eip1.id
  subnet_id = aws_subnet.pub_subnet_2.id
  depends_on = ["aws_internet_gateway.app_igw"]
} */



#APP Security Group

resource "aws_security_group" "app_asg" {
  name        = "APP Security Group"
  description = "Allow HTTP from Load Balancer"
  vpc_id      = aws_vpc.app_vpc.id

/*  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    /*      cidr_blocks = ["0.0.0.0/0"] address allow from lB security group only*/
    cidr_blocks  = ["0.0.0.0/0"]
  } */


  egress {
    from_port   = 0 # need to address
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App SG"
  }

}


resource "aws_security_group_rule" "app_lb_ingress_rule" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  security_group_id = aws_security_group.app_asg.id
  source_security_group_id   = aws_security_group.lb_asg.id
}


#LoadBalancer sg

resource "aws_security_group" "lb_asg" {
  name        = "ALB Security Group"
  description = "Allow HTTP  Traffic from Internet to Load Balancer"
  vpc_id      = aws_vpc.app_vpc.id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

/*  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
*/


  egress {
    from_port   = 0 
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB SG"
  }

}


resource "aws_security_group_rule" "lb_app_ingress_rule" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  security_group_id = aws_security_group.lb_asg.id
  source_security_group_id   = aws_security_group.app_asg.id
}


############ LAUCH Config & Auto Scaling Group ########

resource "aws_iam_instance_profile" "cwdb_iam_profile" {
  name = "cwdb_iam_profile"
  role = aws_iam_role.cwdbrole.name
}

resource "aws_iam_role" "cwdbrole" {
  name = "cwdbrole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

tags = {
 Name = "IAM Role for App"
}
}

resource "aws_iam_policy" "policy" {
  name = "cwdbrole_policy"
  description = "A cloudwatch & ssm parameter"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "ssm:PutParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        },
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:ssm:*:*:parameter/*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::app-artifact-bucket-servian-demo/*"
        }
    ]
}

EOF
tags = {
 Name = "Custom Policy for App"
}

}

resource "aws_iam_role_policy_attachment" "cw_db_policy_attach" {
  role       = aws_iam_role.cwdbrole.name
  policy_arn = aws_iam_policy.policy.arn
}


resource "aws_launch_configuration" "APP-LC" {
  name                 = "APP-LC"
  depends_on           = ["aws_iam_role_policy_attachment.cw_db_policy_attach"] // "aws_security_group.APP-SG-Web"]  addressed required */
  image_id             = var.image_id
  instance_type        = "t2.micro"
  iam_instance_profile = "cwdb_iam_profile"
  security_groups = [aws_security_group.app_asg.id]
  user_data       = file("/root/project/app/deploy/userdata-asg.sh")
  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "APP-ASG" {
  name                      = "APP-ASG"
  depends_on                = ["aws_launch_configuration.APP-LC", "aws_db_instance.app_db"]
  vpc_zone_identifier       = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id]
  max_size                  = 3
  min_size                  = 2
  health_check_grace_period = 300
/*  health_check_type         = "EC2" address required ELB or EC2 */
  health_check_type    = "EC2"
  desired_capacity     = 2
  force_delete         = true
  launch_configuration = aws_launch_configuration.APP-LC.id
//  target_group_arns         = [aws_lb_target_group.APP-TargetGroup.arn]  // Checking required
  lifecycle { create_before_destroy = true }
}

 resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.APP-ASG.id
  alb_target_group_arn   = aws_lb_target_group.APP-TargetGroup.arn
}

resource "aws_lb" "app-alb" {
  name               = "app-alb"
  subnets            = [aws_subnet.pub_subnet_1.id, aws_subnet.pub_subnet_2.id]
  internal           = false
  load_balancer_type = "application"
  security_groups     = [aws_security_group.lb_asg.id]

  tags = {
    Name = "APP ALB"
  }
}

resource "aws_lb_target_group" "APP-TargetGroup" {
  name = "APP-TargetGroup"
//  depends_on  = [aws_vpc.app_vpc.id]
/*  depends_on  = [aws_vpc.app_vpc.id] */
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_vpc.id
  target_type = "instance"

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = true
}
  health_check {
    interval            = 30
    path                = "/healthcheck/"
    port                = 3000
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}

resource "aws_lb_listener" "app-alb-Listener" {
//  depends_on = ["aws_lb.app-alb.id", "aws_lb_target_group.APP-TargetGroup.id"]
  load_balancer_arn = aws_lb.app-alb.arn
//  port              = "3000"
  port     = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.APP-TargetGroup.arn
    type             = "forward"
  }
}


#######################Auto scaling Policy for APP-ASG ##########

resource "aws_autoscaling_policy" "agents-scale-up-cpu" {
    name                   = "agents-scale-up-cpu"
    scaling_adjustment     = 1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.APP-ASG.name
}

resource "aws_autoscaling_policy" "agents-scale-down-cpu" {
    name                   = "agents-scale-down-cpu"
    scaling_adjustment     = -1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.APP-ASG.name
}



resource "aws_autoscaling_policy" "agents-scale-up-mem" {
    name                   = "agents-scale-up-mem"
    scaling_adjustment     = 1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.APP-ASG.name
}

resource "aws_autoscaling_policy" "agents-scale-down-mem" {
    name                   = "agents-scale-down-mem"
    scaling_adjustment     = -1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.APP-ASG.name
}



##################### Cloud Watch Memory Monitoring for APP-ASG ####

resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name          = "mem-util-high"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "2"
    metric_name         = "mem_used_percent"
    namespace           = "CWAgent"
    period              = "60"
    statistic           = "Average"
    threshold           = "80"
    alarm_description   = "This metric monitors ec2 memory for high utilization"
    alarm_actions = [
        aws_autoscaling_policy.agents-scale-up-mem.arn
    ]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.APP-ASG.name
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name          = "mem-util-low"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods  = "2"
    metric_name         = "mem_used_percent"
    namespace           = "CWAgent"
    period              = "60"
    statistic           = "Average"
    threshold           = "60"
    alarm_description   = "This metric monitors ec2 memory for low utilization"
    alarm_actions = [
        aws_autoscaling_policy.agents-scale-down-mem.arn
    ]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.APP-ASG.name
    }
}

##################### Cloud Watch CPU Monitoring for APP-ASG ####

resource "aws_cloudwatch_metric_alarm" "cpu-high" {
    alarm_name          = "cpu-util-high"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "2"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = "60"
    statistic           = "Average"
    threshold           = "80"
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.APP-ASG.name
    }
    alarm_description = "This metric monitor ec2 cpu for high utilization"
    alarm_actions     = [aws_autoscaling_policy.agents-scale-up-cpu.arn]
}


resource "aws_cloudwatch_metric_alarm" "cpu-low" {
  alarm_name          = "cpu-util-low"
  alarm_description   = "This metric monitor ec2 cpu for low utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.APP-ASG.name
  }

  alarm_actions = [aws_autoscaling_policy.agents-scale-down-cpu.arn]
}

################ Output ALB & RDS Endpoint ###########


output "aws_alb" {
  value = aws_lb.app-alb.dns_name
}
