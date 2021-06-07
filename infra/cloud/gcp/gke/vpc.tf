resource "google_compute_network" "vpc" {

    name                    = local.name
    auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "public-subnets" {

    count = length(local.public_subnets)

    name          = "${ local.name }-public-${ count.index }"
    network       = google_compute_network.vpc.name
    ip_cidr_range = local.public_subnets[ count.index ]

}

resource "google_compute_subnetwork" "private-subnets" {

    count = length(local.private_subnets)

    name          = "${ local.name }-private-${ count.index }"
    network       = google_compute_network.vpc.name
    ip_cidr_range = local.private_subnets[ count.index ]

}

resource "google_compute_address" "ingress-ip" {

    name   = "${ local.name }-ingress"
    region = local.region

}
