



variable subnets {
  type = list(string)
}
variable alb_log_s3_bucket {}
variable vpc_id {}


# 8.1
resource "aws_lb" "example" {
  name                       = "example"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = true

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



output "alb_dns_name" {
  value = aws_lb.example.dns_name
}
output "domain_name" {
  value = aws_route53_record.example.name
}
