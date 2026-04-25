data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.environment}-${var.project}-lt-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile
  }
  // --------- Made it dynamic for frontend and backend
  vpc_security_group_ids = [var.security_group_id]
  user_data = base64encode(templatefile("${path.root}/../../Scripts/${var.front_back}_user_data.sh", {
    docker_image       = var.docker_image,
    dockerhub_username = var.dockerhub_username,
    dockerhub_password = var.dockerhub_password,
    environment        = var.environment,
    project            = var.project,

    db_secret_arn = var.db_secret_arn,
    region        = var.region,

    backend_internal_url = var.backend_internal_url
  }))
  //-----------------------------------------

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-${var.project}-frontend"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name = "${var.environment}-${var.project}-${var.front_back}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [var.target_group_arns]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"

  ]

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.project}-${var.front_back}"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.environment}-${var.project}-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-${var.project}-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70.0
  alarm_description   = "Alarm when CPU exceeds 70%"
  alarm_actions       = var.alarm_actions
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  tags = {

    Name = "${var.environment}-${var.project}-high-cpu-alarm"
  }
}
//------------------- Only for frontend -------------------

resource "aws_cloudwatch_metric_alarm" "frontend_unhealthy" {
  count               = var.front_back == "frontend" ? 1 : 0
  alarm_name          = "${var.environment}-${var.project}-frontend-unhealthy-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0.0
  alarm_description   = "Alarm when there are unhealthy hosts in the target group"
  alarm_actions       = var.alarm_actions
  dimensions = {
    TargetGroup = split(":", var.target_group_arns)[5]
  }
}
