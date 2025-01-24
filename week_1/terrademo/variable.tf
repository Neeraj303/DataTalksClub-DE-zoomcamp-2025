variable "credentials" {
  description = "credentials"
  default     = "./keys/my-creds.json"
}

variable "region_india" {
  description = "Region"
  default     = "asia-south1-c"
}

variable "region_us" {
  description = "Region"
  default     = "us-central1"
}

variable "project" {
  description = "Project"
  default     = "hybrid-matrix-448616-b9"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "demo_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "hybrid-matrix-448616-b9"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}