// Using legacy variable declarations
variable "region" {
    type        = string
    description = "Region for the resource."
}

variable "location" {
    type        = string
    description = "Location represents region/zone for the resource."
}

variable "network_name" {
    default = "tf-gke-k8s"
}

// start provider
provider "google" {
    project = "<PROJECT_ID>"
    region = var.region
    zone = var.location
}

resource "google_compute_network" "default" {
    name                    = var.network_name
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
    name                     = var.network_name
    ip_cidr_range            = "10.127.0.0/20"
    network                  = google_compute_network.default.self_link
    region                   = var.region
    private_ip_google_access = true
}

data "google_client_config" "current" {
}

data "google_container_engine_versions" "default" {
    location = var.location
}

resource "google_container_cluster" "default" {
    name               = var.network_name
    location           = var.location
    initial_node_count = 3
    min_master_version = data.google_container_engine_versions.default.latest_master_version
    network            = google_compute_subnetwork.default.name
    subnetwork         = google_compute_subnetwork.default.name
    deletion_protection = false

    // Use legacy ABAC until these issues are resolved:
    //   https://github.com/mcuadros/terraform-provider-helm/issues/56
    //   https://github.com/terraform-providers/terraform-provider-kubernetes/pull/73
    enable_legacy_abac = true

    // Wait for the GCE LB controller to cleanup the resources.
    // Wait for the GCE LB controller to cleanup the resources.
    provisioner "local-exec" {
        when    = destroy
        command = "sleep 90"
    }
}

// defining outputs
output "network" {
    value = google_compute_subnetwork.default.network
}

output "subnetwork_name" {
    value = google_compute_subnetwork.default.name
}

output "cluster_name" {
    value = google_container_cluster.default.name
}

output "cluster_region" {
    value = var.region
}

output "cluster_location" {
    value = google_container_cluster.default.location
}
