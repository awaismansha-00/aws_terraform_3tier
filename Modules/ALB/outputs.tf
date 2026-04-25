output "alb_id" {
  value = aws_lb.lb.id
}

output "alb_arn" {
  value = aws_lb.lb.arn
}
output "alb_dns_name" {
  value = aws_lb.lb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.lb_tg.arn
}

output "alb_zone_id" {
  value = aws_lb.lb.zone_id
}

output "target_group_name" {
  value = aws_lb_target_group.lb_tg.name
}

output "http_listener_arn" {
  value = aws_lb_listener.http_lb_listener.arn
}

output "https_listener_arn" {
  value = try(aws_lb_listener.https[0].arn, null)
}
