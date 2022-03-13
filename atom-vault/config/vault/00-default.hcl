cluster_name = "europe-paris"

ui = true

default_lease_ttl = "168h"
max_lease_ttl = "720h"

api_addr = "http://{{ GetInterfaceIP \"eth0\" }}:8200"
cluster_addr = "http://{{ GetInterfaceIP \"eth0\" }}:8201"

cache {
  use_auto_auth_token = false
}