
data "aws_route53_zone" "stage" {
  name = "alpha.tonberry.org"
}

resource "aws_acm_certificate" "stage" {
  domain_name               = "${var.stage}.tonberry.org"
  subject_alternative_names = ["*.${var.stage}.tonberry.org"]
  validation_method         = "DNS"
}

resource "aws_acm_certificate" "api" {
  domain_name               = "api.${var.stage}.tonberry.org"
  subject_alternative_names = ["*.api.${var.stage}.tonberry.org"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "stage_validation" {
  for_each = {
    for dvo in aws_acm_certificate.stage.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id = data.aws_route53_zone.stage.zone_id
}


resource "aws_route53_record" "api_validation" {
  for_each = {
  for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
  }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id = data.aws_route53_zone.stage.zone_id
}


resource "aws_acm_certificate_validation" "stage" {
  certificate_arn = aws_acm_certificate.stage.arn
  validation_record_fqdns = [for record in aws_route53_record.stage_validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.api_validation : record.fqdn]
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name     = "api.${var.stage}.tonberry.org"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_route53_record" "api" {
  name    = aws_apigatewayv2_domain_name.api.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.stage.id

  alias {
    evaluate_target_health = true
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
  }
}