output "dns_name" {
    value = aws_alb.default.dns_name
}

output "zone_id" {
    value = aws_alb.default.zone_id
}

output "target_group_api" {
    value = aws_alb_target_group.api.arn
}

output "target_group_ui" {
    value = aws_alb_target_group.ui.arn
}