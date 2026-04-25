variable "environment" {
  type = string
}

variable "ami_id" {
  type = string
  default = ""
}

variable "key_name" {
  type = string
}

variable "iam_instance_profile" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "docker_image" {
  type = string
}

variable "dockerhub_username" {
  type = string
}
variable "dockerhub_password" {
  type = string
}
variable "db_secret_arn" {
  type = string
}
variable "region" {
  type = string
}

variable "project" {
  type = string
}
variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "subnet_ids" {
  type = list(string)
}
variable "target_group_arns" {
  type = string
}
variable "alarm_actions" {
  type = list(string)
  default = []
}

variable "backend_internal_url" {
  type = string
}
variable "front_back" {
  type = string
}