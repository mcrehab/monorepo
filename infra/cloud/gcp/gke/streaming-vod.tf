##resource "google_storage_bucket" "auto-expire" {
##
##    name     = "artifacts.nvrai-dev.appspot.com"
##    location = "US"
##
##    lifecycle_rule {
##
##        condition {
##
##            age = 3
##
##        }
##
##        action {
##
##            type = "Delete"
##
##        }
##
##    }
##
##}
#
#resource "google_storage_bucket" "streaming" {
#
#    name     = "${ local.name }-streaming-vod-1"
#    location = local.region
#
#
#}
#
#
#resource "google_service_account" "streaming" {
#
#    account_id   = "streaming-consumer"
#    display_name = "streaming-consumer"
#
#}
#
#resource "google_storage_bucket_iam_member" "streaming" {
#
#    bucket = google_storage_bucket.streaming.name
#    role   = "roles/storage.admin"
#    member = "serviceAccount:${ google_service_account.streaming.email }"
#
#}
#
#resource "google_service_account_key" "streaming" {
#
#    service_account_id = google_service_account.streaming.name
#
#}
#
#resource "local_file" "streaming-key" {
#
#    filename = "out/keys/${ google_service_account.streaming.email }.json"
#    content  = base64decode(google_service_account_key.streaming.private_key)
#
#}
