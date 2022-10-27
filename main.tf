provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  scoutsuite_bucket = "${var.project_id}-scoutsuite"
}

data "google_project" "project" {
}

data "google_organization" "org" {
  domain = var.gcp_domain
}

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 13.0"

  project_id = var.project_id

  activate_apis = [
    "iam.googleapis.com", 
    "cloudresourcemanager.googleapis.com",
    "eventarc.googleapis.com",
    "storage.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com"
  ]

  disable_dependent_services = false
  disable_services_on_destroy = false
}

# Pre-requiste to have a GCS Bucket name with format "<project-id>-scoutsuite"
resource "google_storage_bucket" "bucket" {
  name     = local.scoutsuite_bucket  # Every bucket name must be globally unique
  location = "${var.region}"
  uniform_bucket_level_access = true
}

# Create a service account for Workflows
resource "google_service_account" "scoutsuite_service_account" {
  account_id   = "${var.scoutsuite_sa}-sa"
  display_name = "ScoutSuite Service Account"
}

resource "google_organization_iam_member" "scoutsuite_service_account_roles" {
  org_id  = data.google_organization.org.org_id
  member   = format("serviceAccount:%s", google_service_account.scoutsuite_service_account.email)
  for_each = toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/logging.viewer"
  ])
  role     = each.key
}

# Create a Docker Image Registry on GCP Artifact Repository
resource "google_artifact_registry_repository" "scoutsuite-repo" {
  location      = "${var.region}"
  repository_id = "scoutsuite-repo"
  description   = "scoutsuite docker repository"
  format        = "DOCKER"
}