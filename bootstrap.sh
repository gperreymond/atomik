#!/bin/bash

ACTION=$1
SERVICE=$2

# ------------------------
# BEFORE
# ------------------------

if [ "$ACTION" = "--network-start" ]; then
    docker network create public
fi

if [ "$ACTION" = "--cfssl-start" ]; then
    rm -rf certs
    mkdir certs
    bin/cfssl gencert -initca ca.json | bin/cfssljson -bare certs/root-cert
    bin/cfssl gencert -initca intermediate-ca.json | bin/cfssljson -bare certs/intermediate_ca
    bin/cfssl sign -ca certs/root-cert.pem -ca-key certs/root-cert-key.pem -config cfssl.json -profile intermediate_ca certs/intermediate_ca.csr | bin/cfssljson -bare certs/intermediate_ca
fi

# ------------------------
# ACTIONS
# ------------------------

if [ "$ACTION" = "--start" ]; then
    rm -rf "atom-${SERVICE}/certs"
    mkdir "atom-${SERVICE}/certs"
    if [ -f "atom-${SERVICE}/hostname.json" ]; then
        bin/cfssl gencert -ca certs/intermediate_ca.pem -ca-key certs/intermediate_ca-key.pem -config cfssl.json -profile=peer "atom-${SERVICE}/hostname.json" | bin/cfssljson -bare "atom-${SERVICE}/certs/peer"
        bin/cfssl gencert -ca certs/intermediate_ca.pem -ca-key certs/intermediate_ca-key.pem -config cfssl.json -profile=server "atom-${SERVICE}/hostname.json" | bin/cfssljson -bare "atom-${SERVICE}/certs/server"
        bin/cfssl gencert -ca certs/intermediate_ca.pem -ca-key certs/intermediate_ca-key.pem -config cfssl.json -profile=client "atom-${SERVICE}/hostname.json" | bin/cfssljson -bare "atom-${SERVICE}/certs/client"
    fi
    docker-compose --file atom-${SERVICE}/docker-compose.yaml up --detach --force-recreate
fi

if [ "$ACTION" = "--stop" ]; then
    docker-compose --file atom-${SERVICE}/docker-compose.yaml down
fi

if [ "$ACTION" = "--stop-all" ]; then
    docker-compose --file atom-consul/docker-compose.yaml down
    docker-compose --file atom-ldap/docker-compose.yaml down
    docker-compose --file atom-monitoring/docker-compose.yaml down
    docker-compose --file atom-traefik/docker-compose.yaml down
    docker-compose --file atom-vault/docker-compose.yaml down
    docker network rm public
fi

# ------------------------
# VAULT
# ------------------------

if [ "$ACTION" = "--vault-init" ]; then
    initialized=$(curl -s http://localhost:8200/v1/sys/init | jq -r .initialized)
    echo "[INFO] initialized=${initialized}"
    if [ $initialized = "true" ]; then
        exit 0
    fi
    mkdir data
    docker exec -it vault-server vault operator init -format=json > data/vault.json
fi

if [ "$ACTION" = "--vault-unseal" ]; then
    sealed=$(curl -s http://localhost:8200/v1/sys/seal-status | jq -r .sealed)
    echo "[INFO] sealed=${sealed}"
    if [ $sealed = "true" ]; then
        root_token=$(cat data/vault.json | jq -r .root_token)
        echo "[INFO] root_token=${root_token}"
        unseal_key_1=$(cat data/vault.json | jq -r .unseal_keys_b64[0])
        echo "[INFO] unseal_key_1=${unseal_key_1}"
        unseal_key_2=$(cat data/vault.json | jq -r .unseal_keys_b64[1])
        echo "[INFO] unseal_key_2=${unseal_key_2}"
        unseal_key_3=$(cat data/vault.json | jq -r .unseal_keys_b64[2])
        echo "[INFO] unseal_key_3=${unseal_key_3}"
        curl -s -X PUT -d '{"key":"${unseal_key_1}"}' -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
        curl -s -X PUT -d '{"key":"${unseal_key_2}"}' -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
        curl -s -X PUT -d '{"key":"${unseal_key_3}"}' -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
    fi
fi
