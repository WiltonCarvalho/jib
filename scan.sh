#!/bin/sh
set -ex
podman run --platform=linux/amd64 --name scan -it --rm \
  -v /tmp:/tmp \
  -e TRIVY_CACHE_DIR=/tmp/build_cache/trivy \
  -e TRIVY_INSECURE=true \
  --entrypoint= \
  docker.io/aquasec/trivy \
    trivy image --ignore-unfixed --severity HIGH,CRITICAL \
      --exit-code 0 \
      --security-checks vuln \
      --vuln-type os,library \
      --input /tmp/build_cache/jib-image.tar
