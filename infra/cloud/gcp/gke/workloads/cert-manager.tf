resource "kubernetes_manifest" "cluster-issuer" {

    provider = kubernetes-alpha

    manifest = {

        "apiVersion" = "cert-manager.io/v1"
        "kind"       = "ClusterIssuer"

        "metadata" = {

            name = "default"

        }

        "spec" = {

            acme = {

                email  = "support@mc.rehab"
                server = "https://acme-v02.api.letsencrypt.org/directory"

                privateKeySecretRef = {

                    name = "cert-manager-default"

                }

                solvers = [

                    {

                        http01 = {

                            ingress = {

                                class = "nginx"

                            }

                        }

                    }

                ]

            }

        }

    }

}
