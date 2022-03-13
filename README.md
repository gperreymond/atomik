# ATOMIK

```sh
# part 1
$ ./bootstrap.sh --initialize
$ ./bootstrap.sh --start consul
$ ./bootstrap.sh --start traefik
# part 2
$ ./bootstrap.sh --start vault
$ ./bootstrap.sh --vault-init
$ ./bootstrap.sh --vault-unseal
$ ./bootstrap.sh --vault-enable-ldap
# part 3
$ ./bootstrap.sh --start databases
```

* https://rob-blackbourn.medium.com/how-to-use-cfssl-to-create-self-signed-certificates-d55f76ba5781
* https://cloudinvent.com/blog/howto-hashicorp-vault-ca-pki-deployment/
* https://zestedesavoir.com/billets/3355/traefik-v2-https-ssl-en-localhost/
