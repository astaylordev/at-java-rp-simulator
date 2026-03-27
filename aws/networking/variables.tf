variable "service_name" {
  description = "Name of the service (used for VPC, ALB, and security group naming)"
  type        = string
}

variable "billing_tag_key" {
  description = "The name of the billing tag"
  type        = string
  default     = "CostCentre"
}

variable "billing_tag_value" {
  description = "The value of the billing tag"
  type        = string
}
