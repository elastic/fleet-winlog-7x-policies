variable "stack_version" {
  description = "Elastic stack version"
  default     = "8.13.3"
}

variable "env_id" {
  description = "Suffix to apply to ESS deployment name."
  default     = "manual"
}