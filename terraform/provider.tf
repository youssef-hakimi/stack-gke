# GCP
provider "google" {
  version = "~> 3.0.0-beta.1"
}

provider "google-beta" {
  version = "~> 3.0.0-beta.1"
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
