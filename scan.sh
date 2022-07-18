#!/bin/sh
set -ex
podman run --platform=linux/amd64 -it --rm \
  -v /var/tmp:/var/tmp \
  -e TRIVY_CACHE_DIR=/var/tmp/build_cache/trivy \
  -e TRIVY_INSECURE=true \
  --entrypoint= \
  docker.io/aquasec/trivy:0.29.2 \
    trivy image --ignore-unfixed --severity HIGH,CRITICAL \
      --exit-code 0 \
      --security-checks vuln \
      --vuln-type os,library \
      --input /var/tmp/build_cache/jib-image.tar
