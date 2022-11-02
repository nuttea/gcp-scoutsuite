variable "gcp_domain" {
  description = "The domain name of your gcp organization."
  type        = string
}

variable "project_id" {
  description = "The project to use to run Scoutsuite, Cloud Build and GCS Bucket."
  type        = string
}

variable "region" {
  description = "The Google Cloud region for the GCS Bucket to be created, and the region for Cloud Build to use" 
  default     = "asia-southeast1"
  type        = string
}

variable "scoutsuite_sa" {
  description = "The service account for ScoutSuite."
  default     = "scoutsuite-sa"
  type        = string
}

variable "scan_scope" {
  description = "The scope of where Scoutsuite should scan. Valid inputs are: ' --organization-id <ORGANIZATION ID>'; '--folder-id <FOLDER ID>'; '--project-id <PROJECT ID>'; '--all-projects' (that the service account has access to)"
  default     = "all-projects"
  type        = string
}