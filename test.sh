#!/bin/bash

docker build -f Dockerfile.alpine -t kontena/service-proxy-test .
docker run -i --rm kontena/service-proxy-test rspec spec/
