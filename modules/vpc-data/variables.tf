# Variables for VPC Data Sources Module

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,17}$", var.vpc_id))
    error_message = "The vpc_id must be a valid VPC ID format (vpc-xxxxxxxx)."
  }
}

variable "private_subnet_tags" {
  description = "Tag values to identify private subnets"
  type        = list(string)
  default     = ["Private", "private"]
}

variable "public_subnet_tags" {
  description = "Tag values to identify public subnets"
  type        = list(string)
  default     = ["Public", "public"]
}

variable "use_name_filter" {
  description = "Whether to use name pattern matching instead of Type tags for subnet discovery"
  type        = bool
  default     = false
}

variable "private_subnet_name_patterns" {
  description = "Name patterns to match private subnets when using name filtering"
  type        = list(string)
  default     = ["*private*", "*Private*"]
}

variable "public_subnet_name_patterns" {
  description = "Name patterns to match public subnets when using name filtering"
  type        = list(string)
  default     = ["*public*", "*Public*"]
}

variable "security_group_tags" {
  description = "Map of tags to filter security groups"
  type        = map(list(string))
  default     = {}
}

variable "vpc_name_tag" {     # Referenced but not defined!
  description = "Name tag of the VPC"
  type = string
  default = null
}

variable "validate_network" { # Optional features not controlled
  description = "Whether to validate network configuration"
  type = bool  
  default = false
}

variable "database_subnet_name_patterns" {
  description = "Name patterns to match database subnets"
  type        = list(string)
  default     = ["*database*", "*db*"]
}