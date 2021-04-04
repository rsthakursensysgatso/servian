
### CloudWatch Memory Alarm
# High Memory usage metrics alarm
resource "aws_cloudwatch_metric_alarm" "memory-high" {
  alarm_name          = "mem-util-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 memory for high utilization"
  alarm_actions = [
    aws_autoscaling_policy.agents-scale-up-mem.arn
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.APP-ASG.name
  }
}

# Low Memory usage metrics alarm
resource "aws_cloudwatch_metric_alarm" "memory-low" {
  alarm_name          = "mem-util-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors ec2 memory for low utilization"
  alarm_actions = [
    aws_autoscaling_policy.agents-scale-down-mem.arn
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.APP-ASG.name
  }
}

#### CloudWatch CPU Alarm 
# High CPU usage metrics Alarm
resource "aws_cloudwatch_metric_alarm" "cpu-high" {
  alarm_name          = "cpu-util-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.APP-ASG.name
  }
  alarm_description = "This metric monitor ec2 cpu for high utilization"
  alarm_actions     = [aws_autoscaling_policy.agents-scale-up-cpu.arn]
}


# Low CPU usage metrics Alarm
resource "aws_cloudwatch_metric_alarm" "cpu-low" {
  alarm_name          = "cpu-util-low"
  alarm_description   = "This metric monitor ec2 cpu for low utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.APP-ASG.name
  }

  alarm_actions = [aws_autoscaling_policy.agents-scale-down-cpu.arn]
}
