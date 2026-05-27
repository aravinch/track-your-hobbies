variable "plan_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "docker_image" {
  type = string
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}

variable "acr_login_server" {
  type = string
}

variable "acr_username" {
  type      = string
  sensitive = true
}

variable "acr_password" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}