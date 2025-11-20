provider "google" {
  project = "gcp-devops-demo-478818" 
  region  = "us-central1"
}

terraform {
  backend "gcs" {
    bucket  = "gcp-devops-demo-bucket-sachints" 
    prefix  = "terraform/state"
  }
}