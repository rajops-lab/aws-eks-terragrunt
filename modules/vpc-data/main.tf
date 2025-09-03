# VPC Data Sources Module
# This module fetches information about existing VPC resources using data sources
# It provides a clean interface for accessing VPC, subnets, and related resources

/*
# Step-01. Introduction: 
- Fetch VPC by ID or Name tag using `data "aws_vpc"`.
- Get all Subnets in the VPC.
- Filter Public/Private Subnets using tags or Name patterns.
- Fetch Subnet Details (for private subnets).
- Use Locals to decide subnet selection & map AZs.
- Get Internet/NAT Gateways (optional validation).
- Get Route Tables and associate with subnets.
- Fetch Security Groups (default & tagged).
- Use outputs/locals to pass values to modules.

#### Implemetation plan
Step-01: Introduction                                                       # Done
Step-02: Get existing VPC by ID or Name tags                                # Done
	Step-02-01: Get VPC details using resolved ID                           # Done
	Step-02-02: Find VPC by Name tag (if vpc_name_tag provided)             # Done
Step-03: Get all subnets in the VPC                                         # Done
Step-04: Get private subnets by tag                                         # Done
Step-05: Get public subnets by tag                                          # Done
	Step-05-01: Alternative: Get subnets by name pattern                    # Done
Step-06: Get specific subnet details for each private subnet                # Done
Step-07: Local calculations                                                 # Done
	Step-07-01: Determine which private subnets to use                      # Done
	Step-07-02: Determine which public subnets to use                       # Done
	Step-07-03: Extract availability zones from subnet details              # Done
	Step-07-04: Create subnet map for easy reference                        # Done
Step-08: Optional Network Validation (validate_network = true)              # Done
	Step-08-01: Get Internet Gateway                                        # Done
	Step-08-02: Get NAT Gateways                                            # Done
	Step-08-03: Get Route Tables                                            # Done
Step-09: Optional Advanced Features                                         # Done
	Step-09-01: Get default security group                                  # Done
	Step-09-02: Get existing security groups by tags                        # Done

*/

# Step-02: Get existing VPC by ID or Name

# If the user does not provide VPC ID but provides a Name tag,
# we use aws_vpcs to find VPCs that match the given tag.
# Using `count` makes this block conditional to avoid errors when VPC ID is already known.
data "aws_vpcs" "by_name" {
  count = var.vpc_id == null && var.vpc_name_tag != null ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.vpc_name_tag]
  }
}

# Local variables to determine which input is being used:
# - If var.vpc_id is given, we prefer that
# - If only vpc_name_tag is given, we use the first matching VPC from data.aws_vpcs.by_name
# This logic helps us write cleaner and safer module inputs.
locals {
  use_vpc_id   = var.vpc_id != null
  use_vpc_name = var.vpc_name_tag != null && var.vpc_id == null

  # This is the final VPC ID to use across all resources
  vpc_id = local.use_vpc_id ? var.vpc_id : (
    local.use_vpc_name ? data.aws_vpcs.by_name[0].ids[0] : null
  )
}

# This is the actual VPC data source block used by other resources
# It is decoupled from direct user input and uses the resolved VPC ID from above
data "aws_vpc" "existing" {
  id = local.vpc_id
}


# Step-03: Get all subnets in the VPC
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

# Step-04: Get private subnets by tag
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Type"
    values = var.private_subnet_tags
  }
}

# Step-05: Get public subnets by tag
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Type"
    values = var.public_subnet_tags
  }
}

# Step-05-01: Alternative: Get subnets by name pattern
# Alternative: Get subnets by name pattern
data "aws_subnets" "private_by_name" {
  count = var.use_name_filter ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Name"
    values = var.private_subnet_name_patterns
  }
}

data "aws_subnets" "public_by_name" {
  count = var.use_name_filter ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Name"
    values = var.public_subnet_name_patterns
  }
}

# Database subnets by name pattern
data "aws_subnets" "database_by_name" {
  count = var.use_name_filter ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Name"
    values = var.database_subnet_name_patterns
  }
}

# Step-06: Get specific subnet details for each private subnet
# Get specific subnet details for each private subnet
data "aws_subnet" "private_details" {
  for_each = toset(local.private_subnet_ids)
  id       = each.value
}

# Step-07: Local calculation
# Local calculations
locals {
  # Step-07-01: Determine which private subnets to use 
  # Determine which private subnets to use
  private_subnet_ids = var.use_name_filter ? (
    length(data.aws_subnets.private_by_name) > 0 ? data.aws_subnets.private_by_name[0].ids : []
  ) : data.aws_subnets.private.ids

  # Step-07-02: Determine which public subnets to use
  # Determine which public subnets to use
  public_subnet_ids = var.use_name_filter ? (
    length(data.aws_subnets.public_by_name) > 0 ? data.aws_subnets.public_by_name[0].ids : []
  ) : data.aws_subnets.public.ids

  # Database subnets
database_subnet_ids = var.use_name_filter ? (
  length(data.aws_subnets.database_by_name) > 0 ? data.aws_subnets.database_by_name[0].ids : []
  ) : []
 
  # Step-07-03: Extract availability zones from subnet details
  # Extract availability zones from subnet details
  availability_zones = distinct([
    for subnet in data.aws_subnet.private_details : subnet.availability_zone
  ])
  
  # Step-07-04: Create subnet map for easy reference
  # Create subnet map for easy reference
  private_subnets_by_az = {
    for subnet in data.aws_subnet.private_details :
    subnet.availability_zone => subnet
  }
}

# Step-08: Optional Network Validation (validate_network = true)
# Step-08-01: Get Internet Gateway
# Get existing Internet Gateway
data "aws_internet_gateway" "existing" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing.id]  # or use data.aws_vpc.existing.id if using a VPC data source
  }
}

# Step-08-02: Get NAT Gateways
data "aws_nat_gateways" "all" {
  // count = 1 If you expect only one NAT gateway

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

# Step-08-03: Get Route Tables
# Public route tables (associated with Internet Gateway)
data "aws_route_tables" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "route.gateway-id"
    values = [data.aws_internet_gateway.existing.id]
  }
}

# Private route tables (associated with NAT Gateway)
data "aws_route_tables" "private" {
  count = length(data.aws_nat_gateways.all.ids) > 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "route.nat-gateway-id"
    values = data.aws_nat_gateways.all.ids
  }
}

# Step-09: Optional Advanced Features
# Step-09-01: Get default security group
# Get default security group
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.existing.id
}

# Step-09-02: Get existing security groups by tags
# Get existing security groups by tags (if any)
data "aws_security_groups" "existing" {
  count = length(var.security_group_tags) > 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  dynamic "filter" {
    for_each = var.security_group_tags
    content {
      name   = "tag:${filter.key}"
      values = filter.value
    }
  }
}