resource "aws_appautoscaling_target" "ui_ecs_target" {
  count = var.is_staging_and_staging_off ? 0 : 1

  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.ui.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.is_production ? 2 : 1
  max_capacity       = var.is_production ? 3 : 2
}

resource "aws_appautoscaling_policy" "ui_scale_up" {
  count = var.is_staging_and_staging_off ? 0 : 1

  name               = "ui_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.ui.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.ui_ecs_target[0]]
}

resource "aws_appautoscaling_policy" "ui_scale_down" {
  count = var.is_staging_and_staging_off ? 0 : 1

  name               = "ui_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.ui.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.ui_ecs_target[0]]
}

resource "aws_cloudwatch_metric_alarm" "ui_cpu_high" {
  count = var.is_staging_and_staging_off ? 0 : 1

  alarm_name          = "autoscaling_ui_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    ClusterName = aws_ecs_cluster.default.name
    ServiceName = aws_ecs_service.ui.name
  }

  alarm_actions = [aws_appautoscaling_policy.ui_scale_up[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "ui_cpu_low" {
  count = var.is_staging_and_staging_off ? 0 : 1

  alarm_name          = "autoscaling_ui_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    ClusterName = aws_ecs_cluster.default.name
    ServiceName = aws_ecs_service.ui.name
  }

  alarm_actions = [aws_appautoscaling_policy.ui_scale_down[0].arn]
}
