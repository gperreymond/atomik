cluster_name = "europe-paris"

ui = true

storage "file" {
  path  = "/vault/data"
}

default_lease_ttl = "168h"
max_lease_ttl = "720h"

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://{{ GetInterfaceIP \"eth0\" }}:8200"

cache {
  use_auto_auth_token = false
}