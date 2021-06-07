resource "google_container_cluster" "cluster" {

    name                     = local.name
    location                 = local.region
    node_locations           = [ "us-central1-a" ]
    network                  = google_compute_network.vpc.name
    subnetwork               = google_compute_subnetwork.private-subnets[ 0 ].name
    remove_default_node_pool = true
    initial_node_count       = 1

    cluster_autoscaling {

        enabled = false

    }

    release_channel {

        channel = "RAPID"

    }

    addons_config {

        http_load_balancing {

            disabled = true

        }

        horizontal_pod_autoscaling {

            disabled = true

        }

    }

    resource_usage_export_config {

        enable_network_egress_metering       = true
        enable_resource_consumption_metering = true

        bigquery_destination {

            dataset_id = google_bigquery_dataset.dataset.dataset_id

        }

    }

}

resource "google_container_node_pool" "services-1" {

    name       = "services-1"
    location   = local.region
    cluster    = google_container_cluster.cluster.name
    node_count = 1

    node_config {

        # 4vCPU x 4GB
        machine_type = "e2-highcpu-4"
        disk_size_gb = 30
        preemptible  = true

        labels = {

            role = "services"

        }

    }

}

resource "kubernetes_service_account" "service-account" {

    metadata {

        name      = "root"
        namespace = "default"

    }

}

resource "kubernetes_cluster_role_binding" "service-account" {

    metadata {

        name = "root"

    }

    role_ref {

        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = "cluster-admin"
    }

    subject {

        kind      = "ServiceAccount"
        name      = "root"
        namespace = "default"

    }

}

data "kubernetes_secret" "this" {

    metadata {

        name = kubernetes_service_account.service-account.default_secret_name

    }

}
