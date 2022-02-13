#!/bin/bash

ACTION=$1
SERVICE=$2

# ------------------------
# BEFORE
# ------------------------

if [ "$ACTION" = "--network-create" ]; then
    docker network create public
fi

if [ "$ACTION" = "--gencert-ca" ]; then
    mkdir certs
    ./bin/cfssl gencert -initca ca.json | ./bin/cfssljson -bare certs/root-cert
fi

# ------------------------
# ACTIONS
# ------------------------

if [ "$ACTION" = "--generate-certs" ]; then
    vault_token=$(cat ./data/vault.json | jq -r .root_token)
    domain=$2
    curl -s -H "X-Vault-Token: ${vault_token}" -X POST \
        -d '{"common_name":"traefik.docker.localhost"}' http://localhost:8200/v1/pki/issue/generate-cert-role \
        | jq
fi

if [ "$ACTION" = "--start" ]; then
    
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
        root_token=$(cat ./data/vault.json | jq -r .root_token)
        echo "[INFO] root_token=${root_token}"
        unseal_key_1=$(cat ./data/vault.json | jq -r .unseal_keys_b64[0])
        echo "[INFO] unseal_key_1=${unseal_key_1}"
        unseal_key_2=$(cat ./data/vault.json | jq -r .unseal_keys_b64[1])
        echo "[INFO] unseal_key_2=${unseal_key_2}"
        unseal_key_3=$(cat ./data/vault.json | jq -r .unseal_keys_b64[2])
        echo "[INFO] unseal_key_3=${unseal_key_3}"
        curl -s -X PUT -d '{"key":"${unseal_key_1}"}' -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
        curl -s -X PUT -d '{"key":"${unseal_key_2}"}' -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
        curl -s -X PUT -d '{"key":"${unseal_key_3}"}' -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
    fi
fi

if [ "$ACTION" = "--vault-enable-pki" ]; then
    vault_token=$(cat ./data/vault.json | jq -r .root_token)
    # enable pki service in vault under /pki
    curl -s -H "X-Vault-Token: ${vault_token}" -X POST \
        -d '{"type":"pki"}' http://localhost:8200/v1/sys/mounts/pki
    # configure
    curl -s -H "X-Vault-Token: ${vault_token}" -X POST \
        -d '{"max_lease_ttl":"87600h"}' http://localhost:8200/v1/sys/mounts/pki/tune || true
    curl -s -H "X-Vault-Token: ${vault_token}" -X POST \
        -d '{"common_name":"docker.localhost","ttl":"26280h"}' http://localhost:8200/v1/pki/intermediate/generate/internal | jq -r '.data.csr' > certs/issuing-ca.csr
    curl -s -H "X-Vault-Token: ${vault_token}" -X POST \
        -d '{"issuing_certificates":"http://vault-server:8200/v1/pki/ca","crl_distribution_points":"http://vault-server:8200/v1/pki/crl"}' http://localhost:8200/v1/pki/config/urls || true
    # sign certificate with root certificate
    ./bin/cfssl sign -ca certs/root-cert.pem -ca-key certs/root-cert-key.pem -hostname docker.localhost -config ./signing-config.json certs/issuing-ca.csr | sed -E 's/cert/certificate/' > certs/issuing.pem
    # upload signed to Vault
    curl -s -H "X-Vault-Token: ${vault_token}" -X POST \
        -d @certs/issuing.pem http://localhost:8200/v1/pki/intermediate/set-signed
    # you need to create a role to be able to generate certificates for your domain
    curl -s -H "X-Vault-Token: ${vault_token}" -X POST \
        -d '{"allowed_domains":"docker.localhost","allow_subdomains":true,"max_ttl":"720h"}' http://localhost:8200/v1/pki/roles/generate-cert-role || true
fi
