FROM haproxy:1.5-alpine
MAINTAINER Kontena, Inc. <info@kontena.io>

ENV BACKENDS=kontena-server-api:9292 ACMETOOL_VERSION=0.0.54

RUN apk update && apk --update add curl tzdata bash ruby ruby-rdoc ruby-irb ruby-bigdecimal \
    ruby-io-console ruby-json ruby-rake ca-certificates libssl1.0 openssl libstdc++

ADD Gemfile /app/
ADD Gemfile.lock /app/

RUN apk --update add --virtual build-dependencies ruby-dev build-base openssl-dev && \
    gem install bundler && \
    cd /app ; bundle install --without development test && \
    apk del build-dependencies && \
    mkdir /etc/haproxy

RUN curl -sL -o /tmp/acmetool-v${ACMETOOL_VERSION}-linux_amd64.tar.gz https://github.com/hlandau/acme/releases/download/v${ACMETOOL_VERSION}/acmetool-v${ACMETOOL_VERSION}-linux_amd64.tar.gz && \
    cd /tmp && tar zvxf acmetool-v${ACMETOOL_VERSION}-linux_amd64.tar.gz && \
    mv /tmp/acmetool-v${ACMETOOL_VERSION}-linux_amd64/bin/acmetool /usr/bin/acmetool && \
    mkdir -p /etc/acmetool && mkdir -p /var/lib/acme/conf && \
    echo "provider: https://acme-v01.api.letsencrypt.org/directory" > /var/lib/acme/conf/target

ADD acmetool/response-file.yml /etc/acmetool/response-file.yml
ADD . /app
EXPOSE 80 443
WORKDIR /app

CMD ["./run.sh"]
