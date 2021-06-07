provider "github" {

    owner = local.github_organization
    token = local.github_token

}

module "github-secrets" {

    count = length(local.services)

    source = "./github-secrets"

    secrets = [

        {

            repository      = local.services[ count.index ].repository
            secret_name     = "CLOUD_STORAGE_SERVICE_ACCOUNT_EMAIL"
            plaintext_value = base64decode(google_service_account_key.github.private_key)

        }, {

            repository      = local.services[ count.index ].repository
            secret_name     = "CLOUD_STORAGE_SERVICE_ACCOUNT_KEY"
            plaintext_value = base64decode(google_service_account_key.github.private_key)

        }, {

            repository      = local.services[ count.index ].repository
            secret_name     = "TF_CLOUD_STORAGE_SERVICE_ACCOUNT_KEY"
            plaintext_value = base64decode(google_service_account_key.tf.private_key)

        }, {

            repository      = local.services[ count.index ].repository
            secret_name     = "GKE_ENDPOINT"
            plaintext_value = "https://${ google_container_cluster.cluster.endpoint }"

        }, {

            repository      = local.services[ count.index ].repository
            secret_name     = "GKE_CA"
            plaintext_value = google_container_cluster.cluster.master_auth[ 0 ].cluster_ca_certificate

        }, {

            repository      = local.services[ count.index ].repository
            secret_name     = "GKE_TOKEN"
            plaintext_value = data.kubernetes_secret.this.data.token

        }, {

            repository      = local.services[ count.index ].repository
            secret_name     = "NPM_TOKEN"
            plaintext_value = local.npm_token

        }

    ]

}

