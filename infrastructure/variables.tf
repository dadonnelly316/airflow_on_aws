
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}


variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}
