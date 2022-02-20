cluster_name = "europe-paris"

ui = true

storage "couchdb" {
  endpoint = "http://couchdb:5984/vault"
  username = "admin"
  password = "changeme"
}

default_lease_ttl = "168h"
max_lease_ttl = "720h"

api_addr = "http://{{ GetInterfaceIP \"eth0\" }}:8200"
cluster_addr = "http://{{ GetInterfaceIP \"eth0\" }}:8201"

cache {
  use_auto_auth_token = false
}