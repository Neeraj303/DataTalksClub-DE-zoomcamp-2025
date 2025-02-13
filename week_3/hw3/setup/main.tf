terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

provider "google" {
  credentials = "./keys/my-creds.json"
  project     = "hybrid-matrix-448616-b9"
  region      = "ap-south-1"
}

resource "google_storage_bucket" "demo-bucket" {
  name          = "dezoomcamp_hw3_2025_texnh"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "module3_hw3"
}