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
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com"
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

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.bucket.name
  role = "roles/storage.legacyObjectReader"
  members = [
    "allUsers",
  ]
}

# Create a service account
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
    "roles/logging.viewer",
    "roles/logging.logWriter",
    "roles/storage.objectAdmin"
  ])
  role     = each.key
}

resource "google_project_iam_member" "gcp_sa_cloudbuild_project_roles" {
  project  = var.project_id
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  for_each = toset([
    "roles/secretmanager.secretAccessor"
  ])
  role     = each.key
}

# Dummay Cloud Source Repository for Cloud Build
resource "google_sourcerepo_repository" "dummy_repo" {
  name = "dummy"
}

module "gcloud_init_dummy_repo" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"

  platform = "linux"

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "source repos clone dummy --project=${var.project_id} && cd dummy && git checkout -b main && touch README.md && git add . && git commit -m 'init' && git push -u origin main && cd .. && rm -Rf dummy"

  module_depends_on = [
    google_sourcerepo_repository.dummy_repo
  ]
}

# Create a Docker Image Registry on GCP Artifact Repository
resource "google_artifact_registry_repository" "scoutsuite-repo" {
  location      = "${var.region}"
  repository_id = "scoutsuite-repo"
  description   = "scoutsuite docker repository"
  format        = "DOCKER"
}

module "gcloud_build_image" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"

  platform = "linux"

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit --tag asia-southeast1-docker.pkg.dev/${var.project_id}/scoutsuite-repo/scoutsuite --project ${var.project_id}"

  module_depends_on = [
    google_artifact_registry_repository.scoutsuite-repo
  ]
}

resource "google_cloudbuild_trigger" "build-trigger" {
  name = "scoutsuite-trigger"
  location = "global"
  service_account = google_service_account.scoutsuite_service_account.id

  trigger_template {
    branch_name = "master"
    repo_name   = "dummy"
  }

  build {
    step {
      name = "asia-southeast1-docker.pkg.dev/nuttee-lab-00/scoutsuite-repo/scoutsuite"
      entrypoint = "/bin/bash"
      args = ["-c", 
<<-EOF
  source /root/scoutsuite/bin/activate
  scout gcp --no-browser --report-dir /reports -u --all-projects
EOF
      ]
      volumes {
        name = "reports"
        path = "/reports"
      }
    }
    step {
      name = "gcr.io/cloud-builders/gsutil"
      args = ["cp", "-r", "/reports", "gs://nuttee-lab-00-scoutsuite/"]
      volumes {
        name = "reports"
        path = "/reports"
      }
    }
    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
    timeout = "6000s"
  }
}