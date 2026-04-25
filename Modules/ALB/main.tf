resource "aws_lb" "lb" {
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [var.security_group_ids]
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_delete_protection
  enable_http2                     = true
  enable_cross_zone_load_balancing = true
  idle_timeout                     = 60


  tags = {
    Name        = var.internal ? "${var.environment}-${var.project}-${var.name_prefix}-internal-alb" : "${var.environment}-${var.project}-${var.name_prefix}-external-alb"
    Environment = var.environment
  }
}
resource "aws_lb_target_group" "lb_tg" {
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name        = var.internal ? "${var.environment}-${var.project}-${var.name_prefix}-internal-alb-tg" : "${var.environment}-${var.project}-${var.name_prefix}-external-alb-tg"
    Environment = var.environment
  }
  health_check {
    enabled             = true
    port                = "traffic-port"
    interval            = 30
    protocol            = "HTTP"
    path                = "/health"
    matcher             = "200-299"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

}

resource "aws_lb_listener" "http_lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }

}

resource "aws_lb_listener" "https" {

  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

resource "aws_lb_listener_rule" "redirect_http_to_https" {
  count = var.certificate_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.http_lb_listener.arn

  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

}


