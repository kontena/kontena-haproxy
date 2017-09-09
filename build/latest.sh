#!/bin/bash
set -ue

docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

docker build -t kontena/haproxy:latest .
#docker push kontena/haproxy:latest