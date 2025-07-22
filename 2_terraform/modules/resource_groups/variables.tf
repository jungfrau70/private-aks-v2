variable "use_existing_resource_group_hub" {
  description = "Flag to indicate whether to use existing hub resource group"
  type        = bool
  default     = false
}

variable "use_existing_resource_group_spoke" {
  description = "Flag to indicate whether to use existing spoke resource group"
  type        = bool
  default     = false
}

variable "use_existing_resource_group_storage" {
  description = "Flag to indicate whether to use existing storage resource group"
  type        = bool
  default     = false
}

variable "resource_group_name_hub" {
  description = "Name of the hub resource group"
  type        = string
}

variable "resource_group_name_spoke" {
  description = "Name of the spoke resource group"
  type        = string
}

variable "resource_group_name_storage" {
  description = "Name of the storage resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 