variable "is_production" {
  type = bool
}

variable "is_staging_and_staging_off" {
  type = bool
}

variable "name" {
  type = string
}

variable "rds_sg" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "instance_class" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}