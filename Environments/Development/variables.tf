
variable "environment" {
  type    = string
  default = "dev"
}
variable "project" {
  type    = string
  default = "myapp"
}
variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "frontend_subnet_cidr" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "backend_subnet_cidr" {
  type = list(string)
  default = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}
variable "database_subnet_cidr" {
  type = list(string)
  default = [
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]
}


variable "public_subnet_cidr" {
  type = list(string)
  default = [
    "10.0.10.0/24",
    "10.0.11.0/24"
  ]
}

variable "subnet_az" {
  type = list(string)
  default = [
    "eu-west-2a",
    "eu-west-2b"
  ]
}

variable "allowed_IPs" {
  type    = string
  default = "< Your IP Address>/32"

}

variable "ami" {
  type    = string
  default = "ami-0685f8dd865c8e389"
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

// -------------- DB Variables --------------
variable "db_username" {
  type    = string
  default = "dev_db_admin"
}

variable "db_name" {
  type    = string
  default = "webapp_db"
}

variable "db_engine_version" {
  type    = string
  default = "15.15"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}
variable "db_multi_az" {
  type    = bool
  default = true
}
variable "db_backup_retention" {
  type    = number
  default = 7
}
variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

//------------------------- ASG Variables -------------------------
variable "frontend_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "frontend_min_size" {
  type    = number
  default = 2
}

variable "frontend_max_size" {
  type    = number
  default = 4
}
variable "frontend_desired_capacity" {
  type    = number
  default = 2
}

variable "backend_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "backend_min_size" {
  type    = number
  default = 2
}

variable "backend_max_size" {
  type    = number
  default = 6
}
variable "backend_desired_capacity" {
  type    = number
  default = 2
}

//----------------------------- Docker Variables -----------------------------
variable "frontend_docker_image" {
  type    = string
  default = "<Frontend Docker Image Name>"
}
variable "backend_docker_image" {
  type    = string
  default = "<Backend Docker Image Name>"
}
variable "dockerhub_username" {
  type    = string
  default = ""
}
variable "dockerhub_password" {
  type      = string
  default   = ""
  sensitive = true
}
