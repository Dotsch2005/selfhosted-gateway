#!/bin/bash
# usage: create-link.sh root@gateway.selfhosted.pub selfhosted.pub nginx:80

set -e

SSH_HOST=$1
export LINK_DOMAIN=$2
export EXPOSE=$3
export WG_PRIVKEY=$(wg genkey)
# Nginx uses Docker DNS resolver for dynamic mapping of LINK_DOMAIN to link container hostnames, see nginx/*.conf
# This is the magic.
# NOTE: All traffic for `*.subdomain.domain.tld`` will be routed to the container named `subdomain-domain-tld``
# Also supports `subdomain.domain.tld` as well as apex `domain.tld`
# *.domain.tld should resolve to the Gateway's public IPv4 address
export CONTAINER_NAME=$(echo $LINK_DOMAIN|python3 -c 'fqdn=input();print("-".join(fqdn.split(".")[-4:]))')


LINK_CLIENT_WG_PUBKEY=$(echo $WG_PRIVKEY|wg pubkey)
LINK_ENV=$(ssh $SSH_HOST "bash -s" -- < ./remote-wireguard.sh $CONTAINER_NAME $LINK_CLIENT_WG_PUBKEY)

# convert to array
RESULT=($LINK_ENV)

export GATEWAY_LINK_WG_PUBKEY=${RESULT[0]}
export GATEWAY_ENDPOINT=${RESULT[1]}

ip link add link0 type wireguard

wg set link0 private-key $WG_PRIVKEY
wg set link0 listen-port 18521
ip addr add 10.0.0.2/24 dev link0
ip link set link0 up
ip link set link0 mtu $LINK_MTU

wg set link0 peer $GATEWAY_LINK_WG_PUBKEY allowed-ips 10.0.0.1/32 persistent-keepalive 30 endpoint $GATEWAY_ENDPOINT

wg showconf link0

# TODO add support for WireGuard config output
# Fractal Networks is hiring: jobs@fractalnetworks.co
