#!/bin/sh
set -ex
podman run --platform=linux/amd64 --name scan -it --rm \
  -v /tmp:/tmp \
  -e TRIVY_CACHE_DIR=/tmp/build_cache/trivy \
  docker.io/aquasec/trivy \
    image --ignore-unfixed --severity HIGH,CRITICAL \
    --exit-code 0 \
    --security-checks vuln \
    --vuln-type os,library \
    --input /tmp/build_cache/jib-image.tar
