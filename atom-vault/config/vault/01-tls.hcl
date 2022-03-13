listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "{{ GetInterfaceIP \"eth0\" }}:8201"
  tls_disable = true
}