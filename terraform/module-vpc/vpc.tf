#
# Dedicated VPC
#

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 1.5"

  project_id   = var.gcp_project
  network_name = "${var.project}-gke-${var.env}"
  routing_mode = var.network_routing_mode

  subnets = [
    {
      subnet_name           = "${var.project}-gke-${var.env}-${var.gcp_region}"
      subnet_ip             = var.subnet_cidr
      subnet_region         = var.gcp_region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    "${var.project}-gke-${var.env}-subnet" = [
      {
        range_name    = "${var.project}-gke-${var.env}-${var.gcp_region}-pods"
        ip_cidr_range = var.pods_cidr
      },
      {
        range_name    = "${var.project}-gke-${var.env}-${var.gcp_region}-services"
        ip_cidr_range = var.services_cidr
      },
    ]
  }

  routes = [
    {
      name              = "${var.project}-gke-${var.env}-${var.gcp_region}-egress-inet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
  ]
}

## NAT

# resource "google_compute_address" "project-nat-ips" {
#   count   = "${length(var.cloud_nat_ips)}"
#   name    = "${element(values(var.cloud_nat_ips), count.index)}"
#   project = "${var.gcp_project}"
#   region  = "${var.region}"
# }

# resource “google_compute_router” “project-router” {
#   name = “${var.vpc_name}-nat-router”
#   network = “${google_compute_network.project-network.self_link}”
# }

# resource “google_compute_router_nat” “project-nat” {
#   name = “${var.vpc_name}-nat-gw”
#   router = “${google_compute_router.project-router.name}”
#   nat_ip_allocate_option = “MANUAL_ONLY”
#   nat_ips = [“${google_compute_address.project-nat-ips.*.self_link}”]
#   source_subnetwork_ip_ranges_to_nat = “ALL_SUBNETWORKS_ALL_IP_RANGES”
#   depends_on = [“google_compute_address.project-nat-ips”]
# }
