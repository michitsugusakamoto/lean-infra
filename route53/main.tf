data "aws_route53_zone" "default" {
    name = "sandbox.ctag-timemachine.xyz"
}

resource "aws_route53_record" "api" {
    zone_id = data.aws_route53_zone.default.id
    name    = "api.${var.domain}"
    type    = "A"

    alias {
        zone_id                = var.alb_zone_id
        name                   = var.alb_dns_name
        evaluate_target_health = true
    }
}

resource "aws_route53_record" "ui" {
    zone_id = data.aws_route53_zone.default.id
    name    = "${var.domain}"
    type    = "A"

    alias {
        zone_id                = var.alb_zone_id
        name                   = var.alb_dns_name
        evaluate_target_health = true
    }
}