output "aws_vpc_public_subnets" {
  description = "IDs of the VPC's public subnets"
  value       = module.aws_vpc.public_subnets
}

output "aws_vpc_private_subnets" {
  description = "IDs of the VPC's private subnets"
  value       = module.aws_vpc.private_subnets
}


output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.aws_alb.lb_dns_name
}
