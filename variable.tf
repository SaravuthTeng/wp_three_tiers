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
  description = "The setup environment"
}

### Port for wordpress 
variable "app_port" {
  description = "Port the WordPress application listens on (e.g., 80 or 8080)"
  type        = number
  default     = 80
}
variable "db_password" {
  description = "WP admin password"
  type        = string
  sensitive   = true
#  default     = "admin"  # don't use password here
}
