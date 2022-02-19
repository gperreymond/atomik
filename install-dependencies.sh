#!/bin/bash

MKCERT_VERSION=1.4.3
SOPS_VERSION=3.7.1
TERRAFORM_VERSION=1.1.2
CONSUL_VERSION=1.11.3
NOMAD_VERSION=1.2.5
VAULT_VERSION=1.9.3

rm -rf ./bin
mkdir ./bin

rm -rf ./tmp
mkdir ./tmp

# Download mkcert
echo "[INFO] download mkcert"
curl -sLo ./bin/mkcert https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-amd64
chmod +x ./bin/mkcert
echo "[INFO] mkcert v${MKCERT_VERSION} installed"

# Download sops
echo "[INFO] download sops"
curl -sLo ./sops.zip https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops_${SOPS_VERSION}_amd64.deb
dpkg -x sops.zip tmp
mv tmp/usr/local/bin/sops bin
rm -rf tmp
rm ./sops.zip
chmod +x ./bin/sops
echo "[INFO] sops v${SOPS_VERSION} installed"

# Download terraform
echo "[INFO] download terraform"
curl -sLo ./terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip ./terraform.zip -d ./bin
rm ./terraform.zip
chmod +x ./bin/terraform
echo "[INFO] terraform v${TERRAFORM_VERSION} installed"

# Download consul
echo "[INFO] download consul"
curl -sLo ./consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
unzip ./consul.zip -d ./bin
rm ./consul.zip
chmod +x ./bin/consul
echo "[INFO] consul v${CONSUL_VERSION} installed"

# Download nomad
echo "[INFO] download nomad"
curl -sLo ./nomad.zip https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
unzip ./nomad.zip -d ./bin
rm ./nomad.zip
chmod +x ./bin/nomad
echo "[INFO] nomad v${NOMAD_VERSION} installed"

# Download vault
echo "[INFO] download vault"
curl -sLo ./vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip
unzip ./vault.zip -d ./bin
rm ./vault.zip
chmod +x ./bin/vault
echo "[INFO] vault v${VAULT_VERSION} installed"
