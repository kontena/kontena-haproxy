#!/bin/bash

export RUBY_GC_HEAP_GROWTH_FACTOR=1.1
export RUBY_GC_MALLOC_LIMIT=4000100
export RUBY_GC_MALLOC_LIMIT_MAX=16000100
export RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.1
export RUBY_GC_MALLOC_LIMIT=16000100
export RUBY_GC_OLDMALLOC_LIMIT_MAX=16000100

# fake syslog
socat UNIX-RECV:/dev/log,mode=666 STDOUT &

if [ "${VIRTUAL_HOST}" = "**None**" ]; then
    unset VIRTUAL_HOST
fi

if [ "${SSL_CERT}" = "**None**" ]; then
    unset SSL_CERT
fi

if [ -n "$SSL_CERT" ]; then
    echo -e "${SSL_CERT}" > /etc/ssl/private/servercert.pem
fi

exec /app/bin/kontena-haproxy
