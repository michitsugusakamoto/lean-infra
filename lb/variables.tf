variable "name" {
    type = string
}

variable "public_subnet_ids" {
    type = list(string)
}

variable "alb_security_groups" {
    type = list(string)
}

variable "vpc_id" {
    type = string
}

variable "domain" {
    type = string
}