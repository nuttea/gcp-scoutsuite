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

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 13.0"

  project_id = var.project_id

  activate_apis = [
    "iam.googleapis.com", 
    "cloudresourcemanager.googleapis.com",
    "storage.googleapis.com",
    "containerregistry.googleapis.com",
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
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.bucket.name
  role = "roles/storage.legacyObjectReader"
  members = [
    "allUsers",
  ]
}

# Add IAM Permission to cloudbuild default service account

resource "google_organization_iam_member" "cloudbuild_service_account_roles" {
  org_id  = data.google_organization.org.org_id
  member   = format("serviceAccount:%s", "${data.google_project.project.number}@cloudbuild.gserviceaccount.com")
  for_each = toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/logging.viewer",
    "roles/logging.logWriter",
    "roles/storage.objectAdmin"
  ])
  role     = each.key
  depends_on = [
    module.project_services
  ]
}

resource "time_sleep" "wait_cloudbuild_sa_iam" {
  depends_on      = [google_organization_iam_member.cloudbuild_service_account_roles]
  create_duration = "30s"
}

# Run the Cloud Build Submit for Scout Suite report generation

module "gcloud_build_image" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"

  platform = "linux"

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit build/ --config=build/cloudbuild.yaml --substitutions=_SCOUTSUITE_BUCKET='${google_storage_bucket.bucket.name}' --project ${var.project_id} --timeout=6000s"

  module_depends_on = [
    time_sleep.wait_cloudbuild_sa_iam
  ]
}

output "scoutsuite_report_url" {
  value       = "https://storage.googleapis.com/${google_storage_bucket.bucket.name}/reports/gcp-user-account.html"
  description = "The generated Scout Suite report url in GCS bucket."
}