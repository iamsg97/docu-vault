locals {
  services_map = { for s in var.services : s.name => s }
}

# ── Security groups ───────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Internet-facing ALB — allow HTTP and HTTPS from anywhere"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-alb-sg" }
}

# ECS tasks only accept traffic originating from the ALB — no direct internet access
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name_prefix}-ecs-tasks-sg"
  description = "ECS tasks — inbound from ALB only, unrestricted egress for AWS API calls"
  vpc_id      = var.vpc_id

  ingress {
    description     = "All ports from ALB — dynamic host port assignment"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-ecs-tasks-sg" }
}

# ── ALB ───────────────────────────────────────────────────────────────────

resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  # Keep deletion protection off in dev so terraform destroy works cleanly
  enable_deletion_protection = var.enable_deletion_protection

  tags = { Name = "${var.name_prefix}-alb" }
}

# ── Listeners ─────────────────────────────────────────────────────────────

# HTTP listener — redirect to HTTPS when a cert is available, else forward directly
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.acm_certificate_arn != null ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.acm_certificate_arn != null ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # When no cert — default to webui target group
    target_group_arn = var.acm_certificate_arn == null ? aws_lb_target_group.this[var.default_service].arn : null
  }
}

resource "aws_lb_listener" "https" {
  count             = var.acm_certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.default_service].arn
  }
}

# ── Target groups — one per service ──────────────────────────────────────

resource "aws_lb_target_group" "this" {
  for_each = local.services_map

  name                 = "${var.name_prefix}-${each.key}-tg"
  port                 = each.value.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    path                = each.value.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = { Name = "${var.name_prefix}-${each.key}-tg" }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Listener rules — path-based routing on the active listener ────────────

locals {
  # Route on the HTTPS listener if it exists, otherwise the HTTP listener
  active_listener_arn = (
    var.acm_certificate_arn != null
    ? aws_lb_listener.https[0].arn
    : aws_lb_listener.http.arn
  )
}

resource "aws_lb_listener_rule" "this" {
  for_each = {
    for s in var.services : s.name => s
    if s.name != var.default_service
  }

  listener_arn = local.active_listener_arn
  priority     = each.value.priority

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}
