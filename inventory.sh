#!/bin/sh
# vim: ft=sh syn=sh fileencoding=utf-8 sw=2 ts=2 ai eol et si

set -e
set -u

SSH_CONFIG="$(vagrant ssh-config)"

ssh_opts() { echo "$SSH_CONFIG" | egrep -v '^  (User|IdentityFile)'; }
ssh_opts_nop() { echo "$SSH_CONFIG" | egrep -v '^  (User|Port|IdentityFile)'; }
ssh_port() { echo "$SSH_CONFIG" | awk '/^  Port/ { print $2; }'; }
format_opts() { echo "$1" | awk '/^  / { printf " -o "$1"="$2; }'; }

# SSH_OPTS=$(ssh_opts)
SSH_KEY=${SSH_KEY:-/tmp/.ssh/insecure_id_rsa}
SSH_OPTS="$(format_opts "$(ssh_opts)") -o IdentityFile=${SSH_KEY}"
SSH_OPTS_NOP="$(format_opts "$(ssh_opts_nop)") -o IdentityFile=${SSH_KEY}"
SSH_PORT=$(ssh_port)
DOMAIN=${DOMAIN:-local}
SSH_LOGIN=${SSH_LOGIN:-ops}
PASSWORD=${PASSWORD:-${SSH_LOGIN}}
SSH_PRIVKEY=${SSH_PRIVKEY:-/tmp/.ssh/insecure_id_rsa}

PROXY_CMD="ssh -W %h:%p ${SSH_OPTS} -o User=${SSH_LOGIN} -q sandbox"
UNSEC_OPTS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

cat <<EOF
{
  "vagrant": {
    "hosts": [
      "sandbox.${DOMAIN}"
    ],
    "vars": {
      "ansible_ssh_user": "${SSH_LOGIN}",
      "ansible_become_password": "${PASSWORD}",
      "ansible_ssh_port": ${SSH_PORT},
      "ansible_ssh_common_args": "${SSH_OPTS_NOP}"
    }
  },
  "lxc_hosts": {
    "hosts": [
      "dhcp002.${DOMAIN}",
      "dhcp003.${DOMAIN}",
      "dhcp004.${DOMAIN}",
      "dhcp005.${DOMAIN}",
      "dhcp006.${DOMAIN}",
      "dhcp007.${DOMAIN}",
      "dhcp008.${DOMAIN}",
      "dhcp009.${DOMAIN}"
    ],
    "vars": {
      "ansible_ssh_user": "root",
      "ansible_ssh_common_args": "-o ProxyCommand='${PROXY_CMD}' ${UNSEC_OPTS}"
    }
  }
}
EOF
