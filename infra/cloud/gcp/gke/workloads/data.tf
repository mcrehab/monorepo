data "google_client_config" "config" {

}

data "google_container_cluster" "cluster" {

    project  = "mcrehab-dev"
    name     = "mc-dev-1"
    location = "us-central1"

}
