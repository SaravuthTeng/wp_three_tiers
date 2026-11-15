### Variable use to create something

### aws region
variable "aws_region" {
  type        = string
  default     = "ap-southeast-2"
  description = "The primary AWS target region for the project workload."
}

### vpc block
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The core CIDR block allocated to the dev network environment."
}

### enviroment stage
variable "environment" {
  type        = string
  default     = "dev" 
}
