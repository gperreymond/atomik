#!/bin/bash

ACTION=$1
SERVICE=$2

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

if [ "$ACTION" = "--network-create" ]; then
    docker network create public
fi

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
        curl -s -X PUT -d "{\"key\":\"${unseal_key_1}\"}" -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
        curl -s -X PUT -d "{\"key\":\"${unseal_key_2}\"}" -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
        curl -s -X PUT -d "{\"key\":\"${unseal_key_3}\"}" -H "Content-Type: application/json" http://localhost:8200/v1/sys/unseal | jq
    fi
fi

