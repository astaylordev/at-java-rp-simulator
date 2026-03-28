data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

# VPC with public and private subnets across 2 AZs
module "vpc" {
  source = "github.com/cds-snc/terraform-modules//vpc?ref=main"

  name               = var.service_name
  availability_zones = 2
  enable_flow_log    = false

  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value
}

# Security group: allows HTTP from internet to ALB
resource "aws_security_group" "alb" {
  name        = "${var.service_name}-alb"
  description = "Allow inbound HTTP to the ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP from CloudFront"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

# Security group: allows traffic from ALB to ECS tasks on port 8080
resource "aws_security_group" "ecs" {
  name        = "${var.service_name}-ecs"
  description = "Allow inbound from ALB to ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Port 8080 from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound (ECR, SSM, CloudWatch)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

# Application Load Balancer (internet-facing, HTTP only for scratch)
resource "aws_lb" "app" {
  name               = var.service_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnet_ids

  # Access logging can be enabled once an S3 bucket is configured
  drop_invalid_header_fields = true

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_lb_target_group" "app" {
  name        = var.service_name
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# CloudFront distribution — HTTPS termination in front of the ALB
resource "aws_cloudfront_distribution" "app" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = var.service_name

  origin {
    domain_name = aws_lb.app.dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}
