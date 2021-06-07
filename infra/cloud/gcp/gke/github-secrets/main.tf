variable "secrets" {

    type = list(object({

        repository      = string
        secret_name     = string
        plaintext_value = string

    }))

}

resource "github_actions_secret" "list" {

    count = length(var.secrets)

    repository      = var.secrets[ count.index ].repository
    secret_name     = var.secrets[ count.index ].secret_name
    plaintext_value = var.secrets[ count.index ].plaintext_value

}

