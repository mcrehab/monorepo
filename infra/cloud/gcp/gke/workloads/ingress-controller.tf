module "ingress-controller" {

    source  = "mateothegreat/ingress-controller/kubernetes"
    version = "1.1.2"

    name            = "ingress-controller"
    namespace       = "default"
    vpc_cidr        = "172.201.0.0/16"
    loadbalancer_ip = "35.226.106.254"

    node_selector = {

        role = "services"

    }

}


resource "kubernetes_ingress" "dummy-ingress" {

    metadata {

        name      = "dummy-for-subdomain-cert"
        namespace = "default"

        annotations = {

            "cert-manager.io/cluster-issuer" = "default"

        }

    }

    spec {

        tls {

            hosts       = [ "api.mc.rehab" ]
            secret_name = "api.mc.rehab"

        }

        rule {

            host = "api.mc.rehab"

            http {

                path {

                    backend {

                        service_name = "default-http-backend"
                        service_port = 80

                    }

                }

            }

        }

    }

}
