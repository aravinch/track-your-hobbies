variable "name" {
  description = "ACR name — must be globally unique, alphanumeric only"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy ACR into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}