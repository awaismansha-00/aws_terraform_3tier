output "asg_id" {
  value = aws_autoscaling_group.asg.id
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

output "asge_arn" {
  value = aws_autoscaling_group.asg.arn
}

output "launch_template_id" {
  value = aws_launch_template.lt.id
}

output "launch_template_latest_version" {
  value = aws_launch_template.lt.latest_version
}
