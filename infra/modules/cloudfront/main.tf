# CloudFront sits in front of the ALB to cache static Next.js assets globally
# and to provide a stable public hostname when Route 53 / custom domain is not yet configured.

locals {
  alb_origin_id = "ALBOrigin"
}

resource "aws_cloudfront_distribution" "this" {
  comment             = "${var.name_prefix} — webui + BFF"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = var.price_class
  aliases             = var.domain_names
  default_root_object = ""

  origin {
    domain_name = var.alb_dns_name
    origin_id   = local.alb_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB serves HTTP in dev (no cert yet)
      origin_ssl_protocols   = ["TLSv1.2"]

      # Increase timeout for SSR pages that hit the DB
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }

    custom_header {
      name  = "X-Forwarded-Host"
      value = length(var.domain_names) > 0 ? var.domain_names[0] : var.alb_dns_name
    }
  }

  # ── Cache behaviors ─────────────────────────────────────────────────────

  # Next.js static chunk files — content-hashed filenames, cache forever
  ordered_cache_behavior {
    path_pattern           = "/_next/static/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.alb_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 31536000
    default_ttl = 31536000
    max_ttl     = 31536000
  }

  # API routes — bypass cache entirely, forward all headers + cookies
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.alb_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = false

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type", "X-Request-Id"]
      cookies { forward = "all" }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Default — SSR pages: short cache, forward auth header so Next.js can personalise
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.alb_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "CloudFront-Forwarded-Proto", "Host"]
      cookies { forward = "all" }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 60
  }

  # ── ACM cert (us-east-1 required for CloudFront) ─────────────────────

  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_arn_us_east_1 != null ? [1] : []
    content {
      acm_certificate_arn      = var.acm_certificate_arn_us_east_1
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_arn_us_east_1 == null ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = { Name = "${var.name_prefix}-cf" }
}
