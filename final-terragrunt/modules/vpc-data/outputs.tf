# Outputs for VPC Data Sources Module

# VPC Information
output "vpc_id" {
  description = "ID of the existing VPC"
  value       = data.aws_vpc.existing.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the existing VPC"
  value       = data.aws_vpc.existing.cidr_block
}

# Subnet Information
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.public_subnet_ids
}

output "availability_zones" {
  description = "List of availability zones where private subnets exist"
  value       = local.availability_zones
}

# Security Group Information
output "default_security_group_id" {
  description = "ID of the default security group"
  value       = data.aws_security_group.default.id
}

# Summary for debugging
output "discovery_summary" {
  description = "Summary of discovered resources for debugging"
  value = {
    vpc = {
      id         = data.aws_vpc.existing.id
      cidr_block = data.aws_vpc.existing.cidr_block
    }
    subnets = {
      private_count = length(local.private_subnet_ids)
      public_count  = length(local.public_subnet_ids)
      private_ids   = local.private_subnet_ids
      public_ids    = local.public_subnet_ids
    }
    availability_zones = local.availability_zones
    discovery_method   = var.use_name_filter ? "name_pattern" : "type_tags"
  }
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = local.database_subnet_ids
}