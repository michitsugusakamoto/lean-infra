variable "name" {
    type = string
}

variable "cidr_block" {
    type = string
}

variable "public_subnet_cidrs" {
    type = list(string)
}

variable "private_subnet_cidrs" {
    type = list(string)
}

variable "subnet_azs" {
    type =list(string)
}

variable "vpc_endpoint_sg" {
    type = string
}