datacenter = "europe-paris"

data_dir = "/opt/consul"
log_level  = "INFO"
log_json  = true
server    = true

advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"

bootstrap_expect = 3
retry_join= ["consul-server-1", "consul-server-2", "consul-server-3"]

ui_config {
  enabled = true
}

connect {
  enabled = true
}

ports {
  grpc = 8502
  https = -1
}

