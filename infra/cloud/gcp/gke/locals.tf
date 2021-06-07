locals {

    name            = "mc-dev-1"
    cidr            = "172.202.0.0/16"
    region          = "us-central1"
    subnets         = cidrsubnets(local.cidr, 8, 8, 4, 4, 4, 4)
    public_subnets  = slice(local.subnets, 0, 2)
    private_subnets = slice(local.subnets, 2, 6)

    authorized_networks = [ "47.132.80.116/32" ]

    github_organization = "mcrehab"
    github_token        = "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"
    npm_token           = "7622d35d-614a-4056-a739-f8fa063c6450"

    services = [

        {

            repository = "api"
            path       = "services/api"

        }, {

            repository = "rbac"
            path       = "services/rbac"

        }, {

            repository = "frontend-app"
            path       = "frontends/app"

        }

    ]

}
