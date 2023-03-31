resource "aws_security_group" "alb_sg" {
  name = var.alb_sg_name
  description = var.alb_sg_desc
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
}

resource "aws_lb" "alb" {
  name = var.alb_name
  subnets = aws_subnet.public_subnet[*].id
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "alb_tg" {
  name = var.tg_name
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id
  health_check {
    path = "/"
    protocol = "HTTP"
    timeout = 5
    interval = 30
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_security_group" "lt_sg" {
  name = var.lt_sg
  description = var.lt_sg_desc
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

#I need it to check if docdb instance is ready before connecting to it and launch app
resource "aws_iam_role" "launch_template_role" {
  name = "launch_template_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "documentdb_policy" {
  name = "documentdb_policy"
  role = aws_iam_role.launch_template_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "rds:DescribeDBInstances",
        Resource = aws_docdb_cluster_instance.db.arn
      }
    ]
  })
}

resource "aws_launch_template" "lt" {
  name = var.lt_name
  image_id = var.ec2_ami
  instance_type = var.ec2_type
  iam_instance_profile {
    name = aws_iam_role.launch_template_role.name
  }
  vpc_security_group_ids = [aws_security_group.lt_sg.id]
  user_data = base64encode(templatefile("./user-data.sh", {
    region = var.region
    db_user = var.master_dba
    db_instance = var.db_instance_id
    db_pwd = aws_secretsmanager_secret_version.db_pwd_secret_version.secret_string
    db_endpoint = aws_docdb_cluster.db_cluster.endpoint
  }))
  key_name = "test"
}

resource "aws_autoscaling_group" "asg" {
  name = var.asg_name
  launch_template {
    id = aws_launch_template.lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = aws_subnet.private_subnet[*].id
  target_group_arns = [aws_lb_target_group.alb_tg.arn]
  min_size = 1
  max_size = 2
  desired_capacity          = 1
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}


resource "aws_autoscaling_policy" "asg_policy" {
  name                     = var.asg_policy
  policy_type              = "TargetTrackingScaling"
  estimated_instance_warmup = 120
  autoscaling_group_name   = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    target_value         = 100
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.alb.arn_suffix}/${aws_lb_target_group.alb_tg.arn_suffix}"
    }
  }
}

resource "aws_sns_topic" "topic" {
  name = var.sns_topic_name
}

#resource "aws_sns_topic_subscription" "sns-sub" {
#  topic_arn = aws_sns_topic.topic.arn
#  protocol  = "email"
#  endpoint  = var.support_email
#}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_description   = "CPU Utilization for EC2 instances too high."
  alarm_name          = "EC2 Server HighCPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_percentage_th
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_actions             = [aws_sns_topic.topic.arn]
  ok_actions                = [aws_sns_topic.topic.arn]
  insufficient_data_actions = []
  treat_missing_data        = var.missing_data_behavior
}