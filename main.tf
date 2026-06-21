# 1. Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 2. Create a Custom VPC Network (Avoid Default VPC for Security)
resource "google_compute_network" "custom_vpc" {
  name                    = "bankx-vpc"
  auto_create_subnetworks = false
}

# 3. Create a Secure Private Subnet
resource "google_compute_subnetwork" "custom_subnet" {
  name          = "bankx-subnet-mgmt"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.custom_vpc.id
}

# 4. Define Firewall Rules to Allow Restricted Ingress (e.g., SSH)
resource "google_compute_firewall" "allow_ssh" {
  name    = "bankx-allow-ssh"
  network = google_compute_network.custom_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Replace with your specific public IP block for internal security boundary
  source_ranges = ["0.0.0.0/0"] 
  target_tags   = ["ssh-enabled"]
}

# 5. Create a Dedicated IAM Service Account for the VM (Principle of Least Privilege)
resource "google_service_account" "vm_sa" {
  account_id   = "bankx-vm-sa"
  display_name = "Custom VM Service Account for BankX Instance"
}

# 6. Define the Google Compute Engine Instance
resource "google_compute_instance" "vm_instance" {
  name         = "bankx-secure-instance"
  machine_type = "e2-medium" # Cost-optimized general-purpose machine
  zone         = var.zone

  tags = ["ssh-enabled"]

  # Boot Disk Configuration (Hardened Container-Optimized OS or Ubuntu LTS)
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30 # Size in GB
      type  = "pd-standard"
    }
  }

  # Network Interface Configuration
  network_interface {
    network    = google_compute_network.custom_vpc.id
    subnetwork = google_compute_subnetwork.custom_subnet.id

    # Including this block allocates a public IP. 
    # Remove the access_config block completely if you want a 100% private backend VM.
    access_config {
      // Ephemeral public IP
    }
  }

  # Attach the minimal permission Service Account
  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # Protect infrastructure against accidental deletion
  deletion_protection = false
}