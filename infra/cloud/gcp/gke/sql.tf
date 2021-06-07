resource "google_sql_database_instance" "mysql" {

    name             = local.name
    region           = local.region
    database_version = "MYSQL_8_0"

    settings {

        availability_type = "ZONAL"
        tier              = "db-f1-micro"

        backup_configuration {

            enabled    = true
            start_time = "00:00"

            backup_retention_settings {

                retention_unit   = "COUNT"
                retained_backups = 14

            }

        }

        ip_configuration {

            ipv4_enabled = true

            dynamic "authorized_networks" {

                for_each = local.authorized_networks
                iterator = network

                content {

                    name  = "network-${ network.key }"
                    value = network.value

                }

            }

        }

    }

}

resource "google_sql_database" "database" {

    name     = "mc"
    instance = google_sql_database_instance.mysql.name

}

resource "google_sql_user" "sp" {

    name     = "mc"
    instance = google_sql_database_instance.mysql.name
    password = "Agby5kma0130"

}

resource "google_sql_ssl_cert" "client_cert" {

    common_name = "default"
    instance    = google_sql_database_instance.mysql.name

}
