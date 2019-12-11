# GCP
provider "google" {
  version = "~> 2.18.0"
}

provider "google-beta" {
  version = "~> 2.18.0"
}

# Kubernetes
data "google_client_config" "default" {
}

provider "kubernetes" {
  host                   = "https://${module.gke.control_plane_endpoint}"
  cluster_ca_certificate = base64decode(module.gke.control_plane_ca)
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}
