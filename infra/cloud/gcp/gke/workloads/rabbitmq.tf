module "rabbitmq-cluster" {

    #    source  = "mateothegreat/rabbitmq-cluster/kubernetes"
    #    version = "2.0.5"
    source = "/Users/yomateo/workspace/tf/terraform-kubernetes-rabbitmq-cluster"

    host             = "https://${ data.google_container_cluster.cluster.endpoint }"
    token            = data.google_client_config.config.access_token
    insecure         = true
    namespace        = "default"
    name             = "rabbitmq"
    image            = "rabbitmq:3.7.17-management"
    request_cpu      = "200m"
    request_memory   = "500Mi"
    limit_cpu        = "500m"
    limit_memory     = "700Mi"
    replicas         = 1
    default_username = "rabbitmq"
    default_password = "agaeq14"
    role             = "services"

    labels = {

        #
        # Prevent right sizing of the workload which causes rabbitmq
        # to be rescheduled if downsizing occurs.
        #
        "spotinst.io/restrict-scale-down" = "true"

    }

    persistence = {

        storageClassName = "standard"
        storage          = "1Gi"

    }

}

resource "kubernetes_ingress" "ingress" {

    metadata {

        name      = "rabbitmq-management"
        namespace = "default"

        annotations = {

            "nginx.ingress.kubernetes.io/rewrite-target" = "$1$2"
            "nginx.ingress.kubernetes.io/use-regex"      = true

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

                    path = "/rift/rabbitmq(/|$)(.*)"

                    backend {

                        service_name = "rabbitmq"
                        service_port = 15672

                    }

                }

            }

        }

    }

}
