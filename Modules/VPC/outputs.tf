output "vpc_id" {
  value = aws_vpc.main_vpc.id
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}
output "frontend_subnet_ids" {
  value = aws_subnet.frotnend_subnets[*].id

}
output "backend_subnet_ids" {
  value = aws_subnet.backend_subnets[*].id
}
output "database_subnet_ids" {
  value = aws_subnet.database_subnets[*].id
}
output "nat_gw_ids" {
  value = [for gw in aws_nat_gateway.nat_gw : gw.id]
}

output "ig_id" {
  value = aws_internet_gateway.igw.id
} 
