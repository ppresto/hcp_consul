variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}

variable "target_subnets" {
  description = "target subnets required for awsvpc network config"
  type        = list(any)
}


variable "region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
  default     = "us-east-1"
}