
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
Step-02: Get existing VPC by ID or Name
	Step-02-01: Find VPC by Name tag (if vpc_name_tag provided)
	Step-02-02: Get VPC details using resolved ID
Step-03: Get all subnets in the VPC 
Step-04: Get private subnets by tag
Step-05: Get public subnets by tag
	Step-05-01: Alternative: Get subnets by name pattern
Step-06: Get specific subnet details for each private subnet
Step-07: Local calculations
	Step-07-01: Determine which private subnets to use
	Step-07-02: Determine which public subnets to use
	Step-07-03: Extract availability zones from subnet details
	Step-07-04: Create subnet map for easy reference
Step-08: Optional Network Validation (validate_network = true)
	Step-08-01: Get Internet Gateway
	Step-08-02: Get NAT Gateways
	Step-08-03: Get Route Tables
Step-09: Optional Advanced Features
	Step-09-01: Get default security group
	Step-09-02: Get existing security groups by tags



Step-02. Get all Subnets in the VPC.
Step-03. Filter Public/Private Subnets using tags or Name patterns.
Step-04. Fetch Subnet Details (for private subnets).
Step-05. Use Locals to decide subnet selection & map AZs.
Step-06. Get Internet/NAT Gateways (optional validation).
Step-07. Get Route Tables and associate with subnets.
Step-08. Fetch Security Groups (default & tagged).
Step-09. Use outputs/locals to pass values to modules.
