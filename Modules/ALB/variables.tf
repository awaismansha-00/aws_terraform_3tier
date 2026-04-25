variable "environment" {
  type = string
}

variable "project" {
  type = string
  
}
variable "name_prefix" {
  type = string
}

variable "internal" {
  type = bool
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string
  )
}
variable "security_group_ids" {
  type = string
}
variable "target_group_port" {
  type = number
}
variable "enable_delete_protection" {
  type = bool
}
variable "certificate_arn" {
  type = string
}
