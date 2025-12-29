# Application Load Balancer
resource "aws_lb" "jira" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "jira" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/status"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200,302"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "jira" {
  target_group_arn = aws_lb_target_group.jira.arn
  target_id        = aws_instance.jira.id
  port             = 8080
}

# Local variable to determine if SSL is enabled
locals {
  ssl_enabled = var.domain_name != "" && var.route53_zone_id != ""
}

# HTTP Listener - Redirect to HTTPS (when SSL enabled)
resource "aws_lb_listener" "http_redirect" {
  count = local.ssl_enabled ? 1 : 0

  load_balancer_arn = aws_lb.jira.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTP Listener - Forward to target (when SSL disabled)
resource "aws_lb_listener" "http_forward" {
  count = local.ssl_enabled ? 0 : 1

  load_balancer_arn = aws_lb.jira.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jira.arn
  }
}

# HTTPS Listener (only if SSL enabled)
resource "aws_lb_listener" "https" {
  count = local.ssl_enabled ? 1 : 0

  load_balancer_arn = aws_lb.jira.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.main[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jira.arn
  }
}
