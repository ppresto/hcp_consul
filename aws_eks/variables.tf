variable "name" {
  description = "Name to be used on all the resources as identifier."
  type        = string
  default     = "presto"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}