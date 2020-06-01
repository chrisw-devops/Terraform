variable "cidr_block" {
  description = "The IPv4 VPC range in CIDR notation"
  type = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type = string
}

variable "subnet_newbits" {
  description = "The newbits to add to the CIDR range"
  default = 8
  type = number
}