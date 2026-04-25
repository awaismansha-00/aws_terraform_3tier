variable "vpc_cidr" {
  type = string
}

variable "environment" {
  type = string

}

variable "region" {
  type = string
}

variable "project" {
  type = string
}

variable "frontend_subnet_cidr" {
  type = list(string)
}
variable "backend_subnet_cidr" {
  type = list(string)
}
variable "database_subnet_cidr" {
  type = list(string)
}

variable "public_subnet_cidr" {
  type = list(string)
}

variable "subnet_az" {
  type = list(string)

}

