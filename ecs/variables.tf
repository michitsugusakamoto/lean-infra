variable "is_production" {
  type = bool
}

variable "is_staging_and_staging_off" {
  type = bool
}

variable "name" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "ecs_task_sg" {
  type = string
}

variable "target_group_api" {
  type = string
}

variable "target_group_ui" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_pass" {
  type = string
}

variable "db_name" {
  type = string
}