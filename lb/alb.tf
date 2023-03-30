resource "aws_alb" "default" {
    name            = var.name
    subnets         = var.public_subnet_ids
    security_groups = var.alb_security_groups
}

#api
resource "aws_alb_target_group" "api" {
    name        = "${var.name}-api"
    vpc_id      = var.vpc_id
    port        = "80"
    protocol    = "HTTP"
    target_type = "ip"

    health_check {
        path = "/health"
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_alb_listener" "default_80" {
    load_balancer_arn = aws_alb.default.arn
    port        = "80"
    protocol    = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            status_code  = "503"
            message_body = "503 Error Service Unavailable"
        }
    }
}

resource "aws_alb_listener_rule" "api" {
    listener_arn = aws_alb_listener.default_80.arn
    priority    = 1

    action {
        type             = "forward"
        target_group_arn = aws_alb_target_group.api.arn
    }

    condition {
        host_header {
            values = ["api.${var.domain}"]
        }
    }
}

#ui
resource "aws_alb_target_group" "ui" {
    name        = "${var.name}-ui"
    vpc_id      = var.vpc_id
    port        = "80"
    protocol    = "HTTP"
    target_type = "ip"

    health_check {
        path = "/health"
    }

    lifecycle {
        create_before_destroy = true
    }
}
resource "aws_alb_listener_rule" "ui" {
    listener_arn = aws_alb_listener.default_80.arn
    priority    = 2

    action {
        type             = "forward"
        target_group_arn = aws_alb_target_group.ui.arn
    }

    condition {
        host_header {
            values = [var.domain]
        }
    }
}