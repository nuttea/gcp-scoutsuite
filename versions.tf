terraform {
  required_version = ">= 0.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.41.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.41.0"
    }
  }
}