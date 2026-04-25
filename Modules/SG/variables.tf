variable "environment" {
  type        = string
}

variable "project" {
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_IPs" {
  type = list(string)
}