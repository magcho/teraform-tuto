



variable "subnets" {
  type = list(string)
}
variable "alb_log_s3_bucket" {}
variable "vpc_id" {}


# 8.1
resource "aws_lb" "example" {
  name                       = "example"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false # delete protection するとdestroyできないので困る

  subnets = var.subnets
  access_logs {
    bucket  = var.alb_log_s3_bucket
    enabled = true
  }
  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

# 8.2
module "http_sg" {
  source      = "../security_group"
  name        = "http-sg"
  vpc_id      = var.vpc_id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}
module "https_sg" {
  source      = "../security_group"
  name        = "https-sg"
  vpc_id      = var.vpc_id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}
module "http_redirect_sg" {
  source      = "../security_group"
  name        = "http-redirect-sg"
  vpc_id      = var.vpc_id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

# 8.3
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは[HTTP]です"
      status_code  = "200"
    }
  }
}


# 8.4
data "aws_route53_zone" "example" {
  name = "tf.magcho.com"
}

# 8.6
resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.example.zone_id
  name    = data.aws_route53_zone.example.name
  type    = "A"

  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

# 8.7
resource "aws_acm_certificate" "example" {
  domain_name               = aws_route53_record.example.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true # ブルーグリーンデプロイする（新を作成して置換してから旧を殺す）
  }
}

# 8.8
resource "aws_route53_record" "example_certificate" {
  # 8.7で作成したssl証明書のDNS認証用レコードの登録
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.example.zone_id
}

# 8.9
resource "aws_acm_certificate_validation" "example" {
  # SSL証明書の検証完了まで待機
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [for record in aws_route53_record.example_certificate : record.fqdn]
}


# 8.10
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.example.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは[HTTPS]です"
      status_code  = "200"
    }
  }
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}
output "domain_name" {
  value = aws_route53_record.example.name
}
