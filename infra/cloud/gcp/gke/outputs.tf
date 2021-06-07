output "ingress-ip" {

    value = google_compute_address.ingress-ip

}

resource "local_file" "sql-key" {

    filename = "out/sql/client.key"
    content  = google_sql_ssl_cert.client_cert.private_key

}

resource "local_file" "sql-cert" {

    filename = "out/sql/client.cert"
    content  = google_sql_ssl_cert.client_cert.cert

}

resource "local_file" "sql-ca" {

    filename = "out/sql/client.ca"
    content  = google_sql_ssl_cert.client_cert.server_ca_cert

}

#output "key" {
#
#    value = base64decode(data.kubernetes_secret.this.data.token)
#
#}
#
