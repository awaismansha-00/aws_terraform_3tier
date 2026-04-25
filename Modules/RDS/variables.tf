variable "environment" {
  type = string
}
variable "project" {
  type = string
}
variable "subnet_ids" {
  type = set(string)
}

variable "engine_version" {
  type = string
}
variable "instance_class" {
  type = string
}
variable "allocated_storage" {
  type = number
}


variable "db_name" {
  type = string
}
variable "username" {
  type = string
}
variable "password" {
  type = string
}
variable "port" {
  type = string
}
variable "vpc_security_group_ids" {
  type = list(string)
}

variable "multi_az" {
  type = bool
}
variable "availability_zone" {
  type = string
}

variable "backup_retention_period" {
  type = string
}

variable "backup_window" {
  type = string
  default = "03:00-04:00"
}

variable "maintenance_window" {
  type = string
  default = "mon:04:00-mon:05:00"
}

variable "skip_final_snapshot" {
  type = bool
}

variable "monitoring_interval" {
  type = string
}


variable "deletion_protection" {
  type = string
}
