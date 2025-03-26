#Primary Region 
provider "aws" {
  region = "us-east-1"
}

#Failover Region
provider "aws" {
  region = "us-west-2"
  alias = "failover"
}

#networking Section

#VPC's
resource "aws_vpc" "Primary_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "Primary-VPC"
    Environment = "production-primary"
  }
}
resource "aws_vpc" "Failover_vpc" {
  cidr_block = "10.1.0.0/16"
  provider = aws.failover
  tags = {
    Name        = "Failover-VPC"
    Environment = "production-failover"
  }
}

#Primary Subnets Public 
resource "aws_subnet" "Primary_sub_pub" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "Primary-Public-Subnet-1"
    Environment = "production-primary"
  }
}
resource "aws_subnet" "Primary_sub_pub_2" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name        = "Primary-Public-Subnet-2"
    Environment = "production-primary"
  }
}
#Primary Subnets Private
resource "aws_subnet" "Primary_sub_priv" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name        = "Primary-Private-Subnet"
    Environment = "production-primary"
  }
}

resource "aws_subnet" "Primary_sub_priv2" {
  vpc_id = aws_vpc.Primary_vpc.id
  availability_zone = "us-east-1b"
  cidr_block = "10.0.3.0/24"
  tags = {
    Name        = "Primary-Private-Subnet2"
    Environment = "production-primary"
  }
}

#Failover Subnets Public
resource "aws_subnet" "Failover_sub_pub" {
  vpc_id = aws_vpc.Failover_vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  provider = aws.failover
  tags = {
    Name        = "Failover-Public-Subnet-1"
    Environment = "production-failover"
  }
}
resource "aws_subnet" "Failover_sub_pub_2" {
  vpc_id = aws_vpc.Failover_vpc.id
  cidr_block = "10.1.3.0/24"
    availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  provider = aws.failover
  tags = {
    Name        = "Failover-Public-Subnet-2"
    Environment = "production-failover"
  }
}

#Internet Gateway for Primary VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-IGW"
    Environment = "production-primary"
  }
}
#routetable for Primary VPC
resource "aws_route_table" "RT_prim" {
  vpc_id = aws_vpc.Primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name        = "Primary-Public-RT"
    Environment = "production-primary"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.Primary_sub_pub.id
  route_table_id = aws_route_table.RT_prim.id
}


resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.Primary_sub_pub_2.id
  route_table_id = aws_route_table.RT_prim.id
}


resource "aws_route_table" "RT_Prim_Priv" {
  vpc_id = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-Private-RT"
    Environment = "production-primary"
  }
}  


resource "aws_route_table_association" "rtap1" {
  subnet_id      = aws_subnet.Primary_sub_priv.id
  route_table_id = aws_route_table.RT_Prim_Priv.id
}


resource "aws_route_table_association" "rtap2" {
  subnet_id      = aws_subnet.Primary_sub_priv2.id
  route_table_id = aws_route_table.RT_Prim_Priv.id
}


#Internet Gateway for Failover VPC
resource "aws_internet_gateway" "igw_failover" {
  vpc_id = aws_vpc.Failover_vpc.id
  provider = aws.failover
  tags = {
    Name        = "Failover-IGW"
    Environment = "production-failover"
  }
}
#routetable for Failover VPC
resource "aws_route_table" "RT_Failover" {
  vpc_id = aws_vpc.Failover_vpc.id
  provider = aws.failover

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_failover.id
  }
  tags = {
    Name        = "Failover-Public-RT"
    Environment = "production-failover"
  }
}

resource "aws_route_table_association" "rta1_failover" {
  subnet_id      = aws_subnet.Failover_sub_pub.id
  route_table_id = aws_route_table.RT_Failover.id
  provider = aws.failover
}


resource "aws_route_table_association" "rta1_failover2" {
  subnet_id      = aws_subnet.Failover_sub_pub_2.id
  route_table_id = aws_route_table.RT_Failover.id
  provider = aws.failover
}


########################################################################################################################################################
#Compute section

# IAM Role for EC2 Instances in Primary Region
resource "aws_iam_role" "ec2_role_primary" {
  name = "ec2-role-primary"
  tags = {
    Name        = "EC2-IAM-Role-Primary"
    Environment = "production-primary"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for EC2 Permissions
resource "aws_iam_policy" "ec2_policy_primary" {
  name        = "ec2-policy-primary"
  description = "Permissions for EC2 instances in ASG"
  tags = {
    Name        = "EC2-IAM-Policy-Primary"
    Environment = "production-primary"
  }

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "arn:aws:elasticloadbalancing:region:account-id:targetgroup/Prim_lb_tg"
      }
    ]
  })
}

# Attach IAM Policy to the Role
resource "aws_iam_role_policy_attachment" "attach_policy_primary" {
  role       = aws_iam_role.ec2_role_primary.name
  policy_arn = aws_iam_policy.ec2_policy_primary.arn
}

# IAM Instance Profile for Primary Region
resource "aws_iam_instance_profile" "ec2_instance_profile_primary" {
  name = "ec2-instance-profile-primary"
  role = aws_iam_role.ec2_role_primary.name
}

# IAM Role for EC2 Instances in Failover Region
resource "aws_iam_role" "ec2_role_failover" {
  name     = "ec2-role-failover"
  provider = aws.failover
  tags = {
    Name        = "EC2-IAM-Role-Failover"
    Environment = "production-failover"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for EC2 Permissions in Failover Region
resource "aws_iam_policy" "ec2_policy_failover" {
  name        = "ec2-policy-failover"
  description = "Permissions for EC2 instances in failover ASG"
  provider    = aws.failover
  tags = {
    Name        = "EC2-IAM-Policy-Failover"
    Environment = "production-failover"
  }

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "arn:aws:elasticloadbalancing:region:account-id:targetgroup/Failover_lb_tg"
      }
    ]
  })
}

# Attach IAM Policy to the Role in Failover Region
resource "aws_iam_role_policy_attachment" "attach_policy_failover" {
  role       = aws_iam_role.ec2_role_failover.name
  policy_arn = aws_iam_policy.ec2_policy_failover.arn
  provider   = aws.failover
}

# IAM Instance Profile for Failover Region
resource "aws_iam_instance_profile" "ec2_instance_profile_failover" {
  name     = "ec2-instance-profile-failover"
  role     = aws_iam_role.ec2_role_failover.name
  provider = aws.failover
}

#security groups

resource "aws_security_group" "primary_ec2_sg" {
  name_prefix = "primary-ec2-sg"
  description = "Security group for EC2 instances in the primary region"
  vpc_id      = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-EC2-Security-Group"
    Environment = "production-primary"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.ALB_sg.id] # Only ALB can access EC2
  }
    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}  

resource "aws_security_group" "failover_ec2_sg" {
  name_prefix = "failover-ec2-sg"
  description = "Security group for EC2 instances in the primary region"
  vpc_id      = aws_vpc.Failover_vpc.id
  provider = aws.failover
  tags = {
    Name        = "Failover-EC2-Security-Group"
    Environment = "production-failover"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Failover_ALB_sg.id] # Only ALB can access EC2 
  }
    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"] 
  }
}
data "aws_ami" "amazon_linux_primary" {
  provider    = aws  # Default provider uses the primary region (us-east-1)
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
#Primary launch template 
resource "aws_launch_template" "PrimLT" {
  name          = "primary-launch-template"
  description   = "Launch template for EC2 instances in the primary region"
  image_id      = data.aws_ami.amazon_linux_primary.id  # Use the dynamic AMI ID from the primary region
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.primary_ec2_sg.id] #for priarmy region launch
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile_primary.name
  }
  tags = {
    Name        = "Primary-Launch-Template"
    Environment = "production-primary"
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl enable httpd
              sudo systemctl start httpd

              # Create a basic webpage
              echo "<h1>Primary Region - Web Server</h1>" | sudo tee /var/www/html/index.html

              # Create the /health endpoint for ALB health checks
              echo "healthy" | sudo tee /var/www/html/health

              # Adjust file permissions
              sudo chmod 644 /var/www/html/index.html
              sudo chmod 644 /var/www/html/health
              EOF
  )

  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 10
      volume_type = "gp2"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Primary-ASG-Instance"
    }
  }
}
data "aws_ami" "amazon_linux_failover" {
  provider    = aws.failover  # Uses the failover region (us-west-2)
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
#Failover LT for asg
resource "aws_launch_template" "FailoverLT" {
  provider = aws.failover
  name          = "failover-launch-template"
  description   = "Launch template for EC2 instances in the failover region"
  image_id      = data.aws_ami.amazon_linux_failover.id 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.failover_ec2_sg.id] #for failover region launch
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile_failover.name
  }
  tags = {
    Name        = "Failover-Launch-Template"
    Environment = "production-failover"
  }

 user_data =  base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl enable httpd
              sudo systemctl start httpd

              # Create index.html for testing
              echo "<h1>Failover Region - Web Server</h1>" | sudo tee /var/www/html/index.html

              # Health check endpoint for ALB
              echo "healthy" | sudo tee /var/www/html/health

              # Set correct permissions
              sudo chmod 644 /var/www/html/index.html
              sudo chmod 644 /var/www/html/health
              EOF
  )
  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 10
      volume_type = "gp2"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Failover-ASG-Instance"
    }
  }
}

#Primary ASG
resource "aws_autoscaling_group" "Prim_ASG" {
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  vpc_zone_identifier  = [aws_subnet.Primary_sub_pub.id, aws_subnet.Primary_sub_pub_2.id]

  launch_template {
    id = aws_launch_template.PrimLT.id
    version = aws_launch_template.PrimLT.latest_version
  } 
}
#Failover ASG
resource "aws_autoscaling_group" "Fail_ASG" {
  provider = aws.failover
  min_size             = 0
  max_size             = 5
  desired_capacity     = 0 #Scale up only when needed (saves cost)
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  vpc_zone_identifier  = [aws_subnet.Failover_sub_pub.id, aws_subnet.Failover_sub_pub_2.id]
  launch_template {
    id = aws_launch_template.FailoverLT.id
    version = aws_launch_template.FailoverLT.latest_version
  }
} 
# LB Primary Security group 
resource "aws_security_group" "ALB_sg" {
  name = "Prim_alb_sg"
  vpc_id = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-ALB-Security-Group"
    Environment = "production-primary"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB (Prim)
resource "aws_lb" "Prim_lb" {
  name               = "plb"
  internal           = false # Public facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB_sg.id]
  subnets            = [aws_subnet.Primary_sub_pub.id, aws_subnet.Primary_sub_pub_2.id]
  enable_deletion_protection = false
  tags = {
    Name        = "Primary-ALB"
    Environment = "production-primary"
  }
}

resource "aws_lb_target_group" "Prim_lb_tg" { 
  name     = "plbtg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-Target-Group"
    Environment = "production-primary"
  }

  health_check {
  path                = "/health"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  matcher             = "200"
  }
}

resource "aws_lb_listener" "Prim_lb_lis" {  
  load_balancer_arn = aws_lb.Prim_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Prim_lb_tg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.Prim_ASG.name
  lb_target_group_arn   = aws_lb_target_group.Prim_lb_tg.arn
}

# LB Failover Security group 
resource "aws_security_group" "Failover_ALB_sg" {
  provider = aws.failover
  name     = "Failover_alb_sg"
  vpc_id = aws_vpc.Failover_vpc.id
  tags = {
    Name        = "Failover-ALB-Security-Group"
    Environment = "production-failover"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB (Failover)
resource "aws_lb" "Failover_lb" {
  provider           = aws.failover
  name               = "flb"
  internal           = false # Public facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Failover_ALB_sg.id]
  subnets            = [aws_subnet.Failover_sub_pub.id, aws_subnet.Failover_sub_pub_2.id]
  enable_deletion_protection = false
  tags = {
    Name        = "Failover-ALB"
    Environment = "production-failover"
  }
}

resource "aws_lb_target_group" "Failover_lb_tg" { 
  provider = aws.failover
  name     = "flbtg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.Failover_vpc.id
  tags = {
    Name        = "Failover-Target-Group"
    Environment = "production-failover"
  }

  health_check {
  path                = "/health"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  matcher             = "200"
  }
}

resource "aws_lb_listener" "Failover_lb_lis" {  
  provider          = aws.failover
  load_balancer_arn = aws_lb.Failover_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Failover_lb_tg.arn
  }
}

resource "aws_autoscaling_attachment" "Failover_asg_attach" {
  provider               = aws.failover
  autoscaling_group_name = aws_autoscaling_group.Fail_ASG.name
  lb_target_group_arn    = aws_lb_target_group.Failover_lb_tg.arn
}

#outputs for ALB dns names
output "primary_alb_dns" {
  value = aws_lb.Prim_lb.dns_name
}

output "failover_alb_dns" {           #plb-84901191.us-east-1.elb.amazonaws.com
  value = aws_lb.Failover_lb.dns_name #flb-1639381997.us-west-2.elb.amazonaws.com
}

#Failover section 
# Route 53 hosted zone
resource "aws_route53_zone" "R53HZ" {
  name = "harvey1.com"
  
  tags = {
    Name        = "zone for ALB DNS"
    Environment = "production-primary"
  }
}


# Route 53 record using ALB DNS (primary)
resource "aws_route53_record" "primrecord" {
  zone_id = aws_route53_zone.R53HZ.id
  name    = "harvey1.com"  # Your actual domain name
  type    = "A"
  
  alias {
    name                   = aws_lb.Prim_lb.dns_name
    zone_id                = aws_lb.Prim_lb.zone_id
    evaluate_target_health = true
  } 
  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
 
}
}

# Route 53 record using ALB DNS (failover)
resource "aws_route53_record" "failrecord" {
  zone_id = aws_route53_zone.R53HZ.id
  name    = "harvey1.com"  # Same domain name as primary
  type    = "A"

  alias {
    name                   = aws_lb.Failover_lb.dns_name
    zone_id                = aws_lb.Failover_lb.zone_id
    evaluate_target_health = true
  } 
  set_identifier = "failover"
  failover_routing_policy {
    type = "SECONDARY"
  }
  
}




resource "aws_sns_topic" "ALB_Fail_alerts" {
  name = "ALBFailoverAlerts"
  tags = {
    Name        = "ALB Failover Alerts SNS Topic"
    Environment = "production-primary"
  }
}

# SNS Subscription for ALB Failover Email Alerts
resource "aws_sns_topic_subscription" "ALB_Fail_email_alert" {
  topic_arn = aws_sns_topic.ALB_Fail_alerts.arn
  protocol  = "email"
  endpoint  = "Harvey.Aland.99@outlook.com"
}

# CloudWatch Metric Alarm for ALB Failover
resource "aws_cloudwatch_metric_alarm" "alb_failover_alarm" {
  provider = aws
  alarm_name                = "ALB-Failover-Alarm"
  alarm_description         = "Triggered when ALB targets in the primary region fail and failover to the secondary region occurs"
  metric_name               = "HealthyHostCount"
  namespace                 = "AWS/ApplicationELB"
  statistic                 = "Minimum"
  period                    = 60   # 1-minute period
  evaluation_periods        = 3    # Evaluate for 3 minutes
  threshold                 = 1    # # Triggers if < 1 (so at 0)
  comparison_operator       = "LessThanThreshold"
  dimensions = {
    LoadBalancer = aws_lb.Prim_lb.arn_suffix
    TargetGroup  = aws_lb_target_group.Prim_lb_tg.arn_suffix
  }

  alarm_actions = [aws_sns_topic.ALB_Fail_alerts.arn]

  tags = {
    Name        = "ALB Failover Alarm"
    Environment = "production-primary"
  }
   treat_missing_data = "breaching"  # Fix for handling missing data
}


# Failover Region Lambda Function
resource "aws_lambda_function" "failover_lambda" {
  provider         = aws.failover
  function_name    = "failover-lambda"
  handler          = "failover_lambda.handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = "failover_lambda.zip"  # Reference the zip file
  source_code_hash = filebase64sha256("failover_lambda.zip")  # Ensure updates happen
  
    

  environment {
    variables = {
      FAILOVER_ASG_NAME = aws_autoscaling_group.Fail_ASG.name
    }
  }
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_exec_role" {
  provider = aws.failover
  name     = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
             Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}


# Lambda Policy to Modify Auto Scaling Group
resource "aws_iam_role_policy" "lambda_asg_policy" {
  provider = aws.failover
  role     = aws_iam_role.lambda_exec_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "autoscaling:SetDesiredCapacity"
        Effect   = "Allow"
        Resource = aws_autoscaling_group.Fail_ASG.arn  # Use Terraform reference
      },
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = aws_sns_topic.ALB_Fail_alerts.arn  # Use Terraform reference
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"  # Allow logging to CloudWatch
      }
    ]
  })
}

# SNS Subscription to Trigger Lambda
resource "aws_sns_topic_subscription" "cross_region_subscription" {
  provider  = aws
  topic_arn = aws_sns_topic.ALB_Fail_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.failover_lambda.arn
}

resource "aws_lambda_permission" "sns_invoke_lambda" {
  provider      = aws.failover
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ALB_Fail_alerts.arn
}


#Automated failover simulation check of Primary ALB 
#IAM for the lambda to have access to autoscale the failover ALB

resource "aws_iam_role" "lambda_exec_role_FT" {
  name = "FailoverLambdaExecutionRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role   = aws_iam_role.lambda_exec_role_FT.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_lambda_function" "failover_lambda_FT" {
  provider         = aws.failover
  function_name    = "staged-failover-lambda"
  handler          = "lambda_function.handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_exec_role_FT.arn
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")  
  
  environment {
    variables = {
      PRIMARY_ASG_NAME = aws_autoscaling_group.Prim_ASG.name
    }
  }

  tags = {
    Name        = "Failover Lambda"
    Environment = "Production"
  }
}

#RDS Section: 

# KMS Key 
resource "aws_kms_key" "dbkeyprim" {
  description             = "KMS key for encryption for primary RDS"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage   = "ENCRYPT_DECRYPT"

  tags = {
    Name        = "Primary RDS KMS Key"
    Environment = "production-primary"
  }
}
# RDS Primary instance 
resource "aws_db_instance" "Primrds" {
  allocated_storage    = 20
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.m5.large"
  multi_az             = true
  db_subnet_group_name = aws_db_subnet_group.PrimDBSNG.name
  username             = "username"   #Username and Password would not be hardcoded if deployment went live 
  password             = "password"
  parameter_group_name = "default.mysql8.0"
  backup_retention_period = 7  # Enable backups
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.dbkeyprim.arn # Enable KMS encryption
  skip_final_snapshot  = true

  tags = {
    Environment = "production-primary"
    Name        = "Primary RDS Instance"
  }
}

# RDS Subnet Group consisting of the 2 Primary region private subnets. 
resource "aws_db_subnet_group" "PrimDBSNG" {
  name       = "primary-db-subnet-group"
  subnet_ids = [aws_subnet.Primary_sub_priv.id, aws_subnet.Primary_sub_priv2.id]

  tags = {
    Name        = "Primary RDS Subnet Group"
    Environment = "production-primary"
  }
}

# Backup Vault in Primary Region to Store RDS Backups
resource "aws_backup_vault" "primary_vault" {
  name = "primary-vault"
  tags = {
    Name        = "Primary Backup Vault"
    Environment = "production-primary"
  }
}

# Backup Plan for RDS in Primary Region
resource "aws_backup_plan" "rds_backup_plan" {
  name = "rds-backup-plan"

  # Backup Rule: Daily backups at 12 PM UTC
  rule {
    rule_name         = "backup-rule"
    target_vault_name = aws_backup_vault.primary_vault.name
    schedule          = "cron(0 12 * * ? *)"  # Daily at 12 PM UTC

    lifecycle {
      delete_after = 7  # Retain backups for 7 days before deletion
    }
  }

  tags = {
    Name        = "RDS Backup Plan"
    Environment = "production-primary"
  }
}

# Backup Selection for RDS Instance in Primary Region
resource "aws_backup_selection" "rds_backup_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn  # IAM role used by AWS Backup
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.rds_backup_plan.id
  resources    = [aws_db_instance.Primrds.arn]  # The primary RDS instance to backup
}

# IAM Role for AWS Backup to Manage RDS Backups
resource "aws_iam_role" "backup_role" {
  name = "AWSBackupRDSRole"

  # Trust relationship for AWS Backup service to assume the role
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "backup.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})
}

resource "aws_iam_policy" "backup_rds_policy" {
  name        = "BackupRDSPolicy"
  description = "IAM policy for AWS Backup to manage RDS backups"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "rds:DescribeDBInstances",
          "rds:DescribeDBSnapshots",
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:ListTagsForResource",
          "rds:ListSnapshots",  
          "rds:DescribeDBClusters",  
          "rds:DescribeDBClusterSnapshots",  
          "rds:AddTagsToResource"  
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "backup:StartBackupJob",
          "backup:ListBackupJobs",
          "backup:GetBackupVaultAccessPolicy",
          "backup:CreateBackupVault",
          "backup:DescribeBackupVault",  
          "backup:PutBackupVaultAccessPolicy"  
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": "iam:PassRole",
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })
}

# Attach AWS Backup Service Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "backup_role_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = aws_iam_policy.backup_rds_policy.arn

}

# Primary region RDS SG for access to EC2
resource "aws_security_group" "rds_Prim_sg" {
  name        = "RDS-Primary-SG"
  description = "Allow access to RDS failover instance"
  vpc_id      = aws_vpc.Primary_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.primary_ec2_sg.id]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.Primary_vpc.cidr_block] # Restrict outbound traffic to the VPC
  }

  tags = {
    Name        = "Primary-RDS-SG"
    Environment = "production-primary"
  }
}

# CloudWatch Event Rule for RDS Failover
resource "aws_cloudwatch_event_rule" "rds_failover_rule" {
  name        = "RDS-Failover-Event"
  description = "Triggers when RDS fails over to another AZ"
  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["RDS DB Instance Event"]
    detail = {
      EventCategories = ["failover"]
    }
  })

  tags = {
    Name        = "RDS Failover Event Rule"
    Environment = "production-primary"
  }
}
resource "aws_backup_vault_policy" "primary_vault_policy" {
  backup_vault_name = aws_backup_vault.primary_vault.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": { 
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"  # Grants access to your own account
        },
        "Action": [
          "backup:DescribeBackupVault",
          "backup:StartBackupJob",
          "backup:ListRecoveryPointsByBackupVault",
          "backup:GetBackupVaultAccessPolicy",
          "backup:DeleteRecoveryPoint",
          "backup:StartRestoreJob"
        ],
        "Resource": aws_backup_vault.primary_vault.arn
      }
    ]
  })
}

# Ensure Terraform dynamically fetches your AWS account ID
data "aws_caller_identity" "current" {}

# CloudWatch Event Target for RDS Failover SNS
resource "aws_cloudwatch_event_target" "rds_failover_sns" {
  rule      = aws_cloudwatch_event_rule.rds_failover_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.RDS_Fail_alerts.arn

}

resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.RDS_Fail_alerts.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sns:Publish"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Resource  = aws_sns_topic.RDS_Fail_alerts.arn
      }
    ]
  })
}
# SNS Topic for RDS Fail Alerts
resource "aws_sns_topic" "RDS_Fail_alerts" {
  name = "RDSFailoverAlerts"
  tags = {
    Name        = "RDS Failover Alerts SNS Topic"
    Environment = "production-primary"
  }
}
# SNS Subscription for RDS Failover Email Alerts
resource "aws_sns_topic_subscription" "RDS_Fail_email_alert" {
  topic_arn = aws_sns_topic.RDS_Fail_alerts.arn
  protocol  = "email"
  endpoint  = "Harvey.Aland.99@outlook.com"
}




