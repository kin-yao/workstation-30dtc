variable "active_environment" {
  description = "Which environment receives traffic: blue or green"
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "Must be blue or green."
  }
}

# Blue target group
resource "aws_lb_target_group" "blue" {
  name     = "day12-blue-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Green target group
resource "aws_lb_target_group" "green" {
  name     = "day12-green-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Blue ASG
resource "aws_autoscaling_group" "blue" {
  name_prefix         = "day12-blue-"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.blue.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "day12-blue"
    propagate_at_launch = true
  }
}

# Green ASG
resource "aws_autoscaling_group" "green" {
  name_prefix         = "day12-green-"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.green.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "day12-green"
    propagate_at_launch = true
  }
}

# Blue launch template
resource "aws_launch_template" "blue" {
  name_prefix            = "day12-blue-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Blue environment</h1>
    <p>Instance: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" \
    > /var/www/html/index.html
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Green launch template
resource "aws_launch_template" "green" {
  name_prefix            = "day12-green-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Green environment</h1>
    <p>Instance: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" \
    > /var/www/html/index.html
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Listener rule — one variable controls where traffic goes
resource "aws_lb_listener_rule" "blue_green" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.active_environment == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

output "active_environment" {
  value = var.active_environment
}