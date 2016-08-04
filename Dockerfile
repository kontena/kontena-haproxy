FROM ubuntu:trusty
MAINTAINER Kontena, Inc. <info@kontena.io>

ENV BACKENDS=kontena-server-api:9292 ACMETOOL_VERSION=0.0.54

RUN echo 'deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu trusty main' >> /etc/apt/sources.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x80f70e11f0f0d5f10cb20e62f5da5f09c3173aa6 && \
    echo 'deb http://ppa.launchpad.net/vbernat/haproxy-1.5/ubuntu trusty main' >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 505D97A41C61B9CD && \
    apt-get update

ADD Gemfile /app/
ADD Gemfile.lock /app/

RUN apt-get install -y haproxy ruby2.2 ruby2.2-dev build-essential ca-certificates libssl-dev curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install bundler && \
    cd /app ; bundle install --without development test && \
    apt-get remove -y --purge ruby2.2-dev build-essential gcc g++ dpkg-dev make && \
    apt-get clean && \
    apt-get autoremove -y --purge

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
