# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "flask-vpc"
  auto_create_subnetworks = false
}

# Subnet for GKE
resource "google_compute_subnetwork" "subnet" {
  name          = "flask-subnet"
  region        = "us-central1"
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.0.0.0/16"
}

# --- Database Networking (Private Service Access) ---
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# --- Cloud SQL (MySQL) ---
resource "google_sql_database_instance" "instance" {
  name             = "flask-db-instance-${random_id.db_name_suffix.hex}"
  region           = "us-central1"
  database_version = "MYSQL_8_0"
  deletion_protection = false # For tutorial purposes only

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database" "database" {
  name     = "flaskdb"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = "root" # Default user
  instance = google_sql_database_instance.instance.name
  password = "YourStrongPassword123!"
}

# --- GKE Cluster ---
resource "google_container_cluster" "primary" {
  name     = "flask-gke-cluster"
  location = "us-central1-a"
  
  # We use a VPC-native cluster for Private IP DB access
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  deletion_protection = false
  initial_node_count = 1

  # Delete default node pool to create a custom one
  remove_default_node_pool = true

  ip_allocation_policy {
    # Automatically allocate IPs
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "flask-node-pool"
  location   = "us-central1-a"
  cluster    = google_container_cluster.primary.name
  node_count = 1
  

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}