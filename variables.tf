variable "gcp_domain" {
  description = "The domain name of your gcp organization."
  type        = string
}

variable "project_id" {
  description = "The project in which the resource belongs."
  type        = string
}

variable "region" {
  description = "The Google Cloud regions for the resources to be created."
  default     = "asia-southeast1"
  type        = string
}

variable "scoutsuite_sa" {
  description = "The service account for ScoutSuite."
  default     = "scoutsuite-sa"
  type        = string
}