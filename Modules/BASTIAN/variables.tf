variable "environment" {
  type = string
}

variable "project" {
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
variable "subnet_id" {
  type = string
}