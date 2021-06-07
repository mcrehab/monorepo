resource "google_bigquery_dataset" "dataset" {

    dataset_id = "gke"
    location   = "US"

}

resource "google_bigquery_table" "table" {

    dataset_id = google_bigquery_dataset.dataset.dataset_id
    table_id   = "egress"

}
