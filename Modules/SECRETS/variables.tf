variable "environment" {
  type = string
}
variable "project" {
  type = string
}
variable "db_username" {
  type = string
}
variable "db_password" {
  type = string
}
variable "db_engine" {
  type = string
}
variable "db_host" {
  type = string
}
variable "db_port" {
  type = number
}
variable "db_name" {
  type = string
} 

variable "recovery_window_in_days" {
  type = string
}