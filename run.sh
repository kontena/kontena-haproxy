#!/bin/sh

if [ "${VIRTUAL_HOST}" = "**None**" ]; then
    unset VIRTUAL_HOST
fi

if [ "${SSL_CERT}" = "**None**" ]; then
    unset SSL_CERT
fi

if [ -n "$SSL_CERT" ]; then
    echo -e "${SSL_CERT}" > /etc/haproxy/servercert.pem
    export SSL="ssl crt /etc/haproxy/servercert.pem"
fi

exec /app/bin/kontena-haproxy
