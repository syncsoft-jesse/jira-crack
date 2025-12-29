# ACM Certificate for SSL/TLS
resource "aws_acm_certificate" "main" {
  count = var.domain_name != "" ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = var.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cert"
  }
}

# Route 53 DNS records for ACM validation
resource "aws_route53_record" "acm_validation" {
  for_each = var.domain_name != "" && var.route53_zone_id != "" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

# Certificate validation
resource "aws_acm_certificate_validation" "main" {
  count = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# Route 53 A record for ALB (optional - only if zone_id provided)
resource "aws_route53_record" "jira" {
  count = var.domain_name != "" && var.route53_zone_id != "" && var.create_route53_record ? 1 : 0

  zone_id         = var.route53_zone_id
  name            = var.domain_name
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.jira.dns_name
    zone_id                = aws_lb.jira.zone_id
    evaluate_target_health = true
  }
}
