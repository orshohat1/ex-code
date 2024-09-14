variable "public_key" {
  description = "MongoDB Atlas public API key"
  type        = string
}

variable "private_key" {
  description = "MongoDB Atlas private API key"
  type        = string
}

variable "org_id" {
  description = "MongoDB Atlas organization ID"
  type        = string
}

variable "project_name" {
  description = "The name of the MongoDB Atlas project"
  type        = string
}

variable "provider_name" {
  description = "Cloud provider for the MongoDB cluster (AWS, GCP, AZURE)"
  type        = string
  default     = "AWS" 
}

variable "provider_region_name" {
  description = "The region in which to deploy the MongoDB cluster"
  type        = string
  default     = "US_EAST_1"  # Change to a region supported by AWS free-tier
}

variable "cluster_name" {
  description = "The name of the MongoDB Atlas cluster"
  type        = string
}