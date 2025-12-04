variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment_name" {
  description = "Name of the environment (e.g., dev, prod)"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}
