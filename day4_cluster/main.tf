provider "aws" {
  region = var.aws_region
}

# --- Data sources ---

data "aws_availability_zones" "all" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security group for ALB ---
# Only allows inbound HTTP from the internet

resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# --- Security group for EC2 instances ---
# Only allows inbound traffic FROM the ALB security group
# Instances are never directly reachable from the internet

resource "aws_security_group" "instance_sg" {
  name        = "${var.environment}-instance-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-instance-sg"
    Environment = var.environment
  }
}

# --- Launch Template ---
# Defines what each EC2 instance in the ASG looks like

resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Day 4 - Clustered Terraform Deployment</h1>
              <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
              <p>AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
              <p>Environment: ${var.environment}</p>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-asg-instance"
      Environment = var.environment
      Project     = "30-day-terraform-challenge"
    }
  }
}

# --- Application Load Balancer ---

resource "aws_lb" "web" {
  name               = "${var.environment}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name        = "${var.environment}-web-alb"
    Environment = var.environment
  }
}

# --- Target Group ---
# The ALB forwards traffic here; health checks run against /

resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-web-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# --- ALB Listener ---
# Tells the ALB what to do with incoming traffic on port 80

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# --- Auto Scaling Group ---

resource "aws_autoscaling_group" "web" {
  name                = "${var.environment}-web-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.min_size
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}