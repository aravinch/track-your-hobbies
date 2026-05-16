variable "name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region — e.g. East US, UK South"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}