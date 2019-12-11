#
# General
#

variable "gcp_project" {
  description = "The Google Cloud Platform project to use."
}

variable "gcp_region" {
  description = "The Google Cloud Platform region to use."
  default     = "eu-central1"
}

variable "gcp_zones" {
  description = "To use specific Google Cloud Platform zones if not regional, otherwise it will be chosen randomly."
  default     = []
}

data "google_compute_zones" "available" {
  project = var.gcp_project
  region  = var.gcp_region
  status  = "UP"
}

locals {
  gcp_availability_zones = length(var.gcp_zones) > 0 ? var.gcp_zones : data.google_compute_zones.available.names
}

variable "project" {
  description = "Cycloid project name."
}

variable "env" {
  description = "Cycloid environment name."
}

variable "customer" {
  description = "Cycloid customer name."
}

variable "extra_labels" {
  description = "Extra labels to add to all resources."
  default     = {}
}

locals {
  standard_labels = {
    cycloidio    = "true"
    env          = var.env
    project      = var.project
    client       = var.customer
  }
  merged_labels = merge(local.standard_labels, var.extra_labels)
}

#
# Networking
#

variable "subnet_name" {
  description = "GKE Cluster subnet name to use."
}

variable "pods_ip_range" {
  description = "GKE Cluster pods IP range to use."
}

variable "services_ip_range" {
  description = "GKE Cluster services IP range to use."
}

variable "master_cidr" {
  description = "GKE Cluster masters IP CIDR to use."
  default     = "172.16.0.0/28"
}

#
# Control plane
#

variable "cluster_name" {
  description = "GKE Cluster given name."
}

variable "cluster_version" {
  description = "GKE Cluster version to use."
  default     = "latest"
}

variable "cluster_regional" {
  description = "If the GKE Cluster must be regional or zonal. Be careful, this setting is destructive."
  default     = false
}

variable "control_plane_allowed_ips" {
  description = "Allow Inbound IP CIDRs to access the Kubernetes API."
  default     = []
}

variable "enable_network_policy" {
  description = "Enable GKE Cluster network policies addon."
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable GKE Cluster horizontal pod autoscaling addon."
  default     = true
}

variable "enable_http_load_balancing" {
  description = "Enable GKE Cluster HTTP load balancing addon."
  default     = false
}

variable "disable_legacy_metadata_endpoints" {
  description = "Disable GKE Cluster legacy metadata endpoints."
  default     = true
}

#
# Node pools
#

variable "node_pools" {
  description = "GKE Cluster node pools to create."
  default     = []
}