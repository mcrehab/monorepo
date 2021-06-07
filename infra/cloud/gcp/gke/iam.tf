resource "google_service_account" "github" {

    account_id   = "github"
    display_name = "github"

}

resource "google_storage_bucket_iam_member" "github" {

    bucket = "artifacts.mcrehab-dev.appspot.com"
    role   = "roles/storage.admin"
    member = "serviceAccount:${ google_service_account.github.email }"

}

resource "google_service_account_key" "github" {

    service_account_id = google_service_account.github.name

}

#
# tf
#
resource "google_service_account" "tf" {

    account_id   = "github-tf"
    display_name = "github-tf"

}

resource "google_storage_bucket_iam_member" "tf" {

    bucket = "mcrehab-dev-tf"
    role   = "roles/storage.admin"
    member = "serviceAccount:${ google_service_account.tf.email }"

}

resource "google_service_account_key" "tf" {

    service_account_id = google_service_account.tf.name

}

