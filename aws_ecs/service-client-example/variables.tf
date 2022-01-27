variable "name" {
  description = "Service Name"
  type        = string
}
variable "region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
  default     = "us-east-1"
}
variable "target_subnets" {
  description = "target subnets required for awsvpc network config"
  type        = list(any)
}
variable "alb_subnets" {
  description = "target subnets for ALB"
  type        = list(any)
}
variable "vpc_id" {
  description = "target VPC for security groups"
  type        = string
}

variable "security_group_id" {
  description = "target security group for alb"
  type        = string
}

variable "lb_ingress_ip" {
  description = "Use your local IP to secure ingress traffic to ALB"
  default     = "52.119.127.230"
}

variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}

variable "dns_namespace" {
  description = "private dns namespace for ECS fake-service discovery"
  type        = string
  default     = "presto.local"
}

variable "dns_fake_server" {
  description = "Route53 DNS name for ECS fake-server"
  type        = string
  default     = "fake-server"
}