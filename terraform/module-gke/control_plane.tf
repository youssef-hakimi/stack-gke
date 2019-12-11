
data "google_compute_subnetwork" "subnetwork" {
  name       = var.subnet_name
  project    = var.gcp_project
  region     = var.gcp_region
}

module "gcp-gke" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster-update-variant"
  version      = "~> 6.1"
  
  project_id = var.gcp_project
  region     = var.gcp_region

  name               = var.cluster_name
  regional           = var.cluster_regional
  zones              = var.cluster_regional ? null : slice(local.gcp_available_zones, 0, 1)
  kubernetes_version = var.cluster_version

  // This craziness gets a plain network name from the reference link which is the
  // only way to force cluster creation to wait on network creation without a
  // depends_on link.  Tests use terraform 0.12.6, which does not have regex or regexall
  network = reverse(split("/", data.google_compute_subnetwork.subnetwork.network))[0]

  subnetwork              = data.google_compute_subnetwork.subnetwork.name
  ip_range_pods           = var.pods_ip_range
  ip_range_services       = var.services_ip_range

  create_service_account            = true
  enable_private_endpoint           = true
  grant_registry_access             = true
  network_policy                    = var.enable_network_policy
  horizontal_pod_autoscaling        = var.enable_horizontal_pod_autoscaling
  http_load_balancing               = var.enable_http_load_balancing
  disable_legacy_metadata_endpoints = var.disable_legacy_metadata_endpoints

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  master_ipv4_cidr_block     = var.master_cidr
  master_authorized_networks = concat(
    [
      {
        cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
        display_name = "VPC"
      },
    ],
    [
      for allowed_ip in var.control_plane_allowed_ips: {
        cidr_block   = allowed_ip["cidr"]
        display_name = allowed_ip["name"]
      }
    ]
  )

  enable_private_nodes     = true
  remove_default_node_pool = true
  node_pools               = var.node_pools

  node_pools_oauth_scopes = merge(
    {
      all = [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/trace.append",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/servicecontrol",
      ]
    },
    zipmap(
      [for node_pool in var.node_pools : node_pool["name"]],
      [for node_pool in var.node_pools : node_pool["oauth_scopes"]]
    ),
  )

  node_pools_labels = merge(
    {
      all = {}
    },
    zipmap(
      [for node_pool in var.node_pools : node_pool["name"]],
      [for node_pool in var.node_pools : node_pool["labels"]]
    ),
  )

  node_pools_metadata = merge(
    {
      all = {
        shutdown-script = file("${path.module}/data/shutdown-script.sh")
      }
    },
    zipmap(
      [for node_pool in var.node_pools : node_pool["name"]],
      [for node_pool in var.node_pools : node_pool["metadata"]]
    ),
  )

  node_pools_taints = merge(
    {
      all = {}
    },
    zipmap(
      [for node_pool in var.node_pools : node_pool["name"]],
      [for node_pool in var.node_pools : node_pool["taints"]]
    ),
  )

  node_pools_tags = merge(
    {
      all = []
    },
    zipmap(
      [for node_pool in var.node_pools : node_pool["name"]],
      [for node_pool in var.node_pools : node_pool["tags"]]
    ),
  )

  cluster_resource_labels = merge(local.merged_labels, {
    Name = "${var.project}-${var.env}-gke-cluster"
  })
}

data "google_client_config" "default" {
}
