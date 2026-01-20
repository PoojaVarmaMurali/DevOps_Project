variable "vpc_id" {
  type = string
}

variable "alb_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "frontend_image" {
  type = string
}

variable "backend_image" {
  type = string
}
