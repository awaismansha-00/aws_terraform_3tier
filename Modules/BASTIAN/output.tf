output "bastian_instance_id" {
  value = aws_instance.bastian_host.id
}
output "bastian_public_ip" {
  value = aws_eip.bastian_eip.public_ip
}
output "bastian_private_ip" {
  value = aws_instance.bastian_host.private_ip
}
