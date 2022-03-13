#!/bin/bash

ACTION=$1
SERVICE=$2

# ------------------------
# BEFORE
# ------------------------

if [ "$ACTION" = "--initialize" ]; then
    docker network create public
    ./bin/mkcert -install
fi

# ------------------------
# ACTIONS
# ------------------------

if [ "$ACTION" = "--start" ]; then
    rm -rf "atom-${SERVICE}/certs"
    if [ -f "atom-${SERVICE}/hostname.txt" ]; then
        mkdir "atom-${SERVICE}/certs"
        ./bin/mkcert -cert-file "atom-${SERVICE}/certs/local-cert.pem" -key-file "atom-${SERVICE}/certs/local-key.pem" "docker.localhost" "*.docker.localhost"
    fi
    if [ "$SERVICE" = "databases" ]; then
        echo "[INFO] databases, something to do..."
    fi
    docker-compose --env-file .env --file atom-${SERVICE}/docker-compose.yaml up --detach --force-recreate
fi

if [ "$ACTION" = "--stop" ]; then
    docker-compose --file atom-${SERVICE}/docker-compose.yaml down
fi

if [ "$ACTION" = "--stop-all" ]; then
    docker-compose --env-file .env --file atom-ldap/docker-compose.yaml down
    docker-compose --env-file .env --file atom-monitoring/docker-compose.yaml down
    docker-compose --env-file .env --file atom-traefik/docker-compose.yaml down
    docker-compose --env-file .env --file atom-vault/docker-compose.yaml down
    docker-compose --env-file .env --file atom-consul/docker-compose.yaml down
    docker network rm public
fi

# ------------------------
# VAULT
# ------------------------

if [ "$ACTION" = "--vault-init" ]; then
    initialized=$(curl -s https://vault.docker.localhost/v1/sys/init | jq -r .initialized)
    echo "[INFO] initialized=${initialized}"
    if [ $initialized = "true" ]; then
        exit 0
    fi
    mkdir data
    docker exec -it vault-server-1 vault operator init -format=json > data/vault.json
fi

if [ "$ACTION" = "--vault-unseal" ]; then
    sealed=$(curl -s https://vault.docker.localhost/v1/sys/seal-status | jq -r .sealed)
    echo "[INFO] sealed=${sealed}"
    if [ $sealed = "true" ]; then
        unseal_key_1=$(cat data/vault.json | jq -r .unseal_keys_hex[0])
        echo "[INFO] unseal_key_1=${unseal_key_1}"
        docker exec -it vault-server-1 vault operator unseal ${unseal_key_1}
        docker exec -it vault-server-2 vault operator unseal ${unseal_key_1}
        unseal_key_2=$(cat data/vault.json | jq -r .unseal_keys_hex[1])
        echo "[INFO] unseal_key_2=${unseal_key_2}"
        docker exec -it vault-server-1 vault operator unseal ${unseal_key_2}
        docker exec -it vault-server-2 vault operator unseal ${unseal_key_2}
        unseal_key_3=$(cat data/vault.json | jq -r .unseal_keys_hex[2])
        echo "[INFO] unseal_key_3=${unseal_key_3}"
        docker exec -it vault-server-1 vault operator unseal ${unseal_key_3}
        docker exec -it vault-server-2 vault operator unseal ${unseal_key_3}
    fi
fi

if [ "$ACTION" = "--vault-enable-ldap" ]; then
    root_token=$(cat data/vault.json | jq -r .root_token)
    echo "[INFO] root_token=${root_token}"
    docker exec -it vault-server-1 vault login $root_token
    docker exec -it vault-server-1 vault auth enable ldap
    # auth ldap
    docker exec -it vault-server-1 vault write auth/ldap/config \
        url="ldap://ldap-server" \
        binddn="uid=ldap.bind,ou=people,dc=docker,dc=localhost" \
        bindpass="scott-Deny-slower-44" \
        userdn="ou=people,dc=docker,dc=localhost" \
        userattr="uid" \
        groupdn="ou=groups,dc=docker,dc=localhost" \
        groupattr="cn" \
        deny_null_bind=true \
        insecure_tls=false
    docker exec -it vault-server-1 vault policy write vault-admins /etc/vault/policies/vault-admins.hcl
    docker exec -it vault-server-1 vault write auth/ldap/groups/vault-admins policies=vault-admins
fi
