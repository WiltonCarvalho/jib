#!/bin/bash
set -e
podman run --platform=linux/amd64 --name builder -it --rm \
  -v /tmp:/tmp \
  -e GRADLE_USER_HOME=/tmp/build_cache/gradle \
  -v $PWD:/code:ro -w /code \
  docker.io/library/openjdk:11-jdk \
    sh -c '
      set -ex
      cp -r /code /home/code
      cd /home/code
      pwd
      exec ./gradlew --info --init-script init.gradle jibBuildTar \
        -Djib.console=plain \
        -Djib.from.image=docker.io/library/openjdk:11-jre \
        -Djib.from.platforms=linux/amd64 \
        -Djib.allowInsecureRegistries=true \
        -Djib.outputPaths.tar=/tmp/build_cache/jib-image.tar
    '

echo -e '\nLoading Image...\n'
podman load -i /tmp/build_cache/jib-image.tar | \
  awk '{print $NF}' | \
  xargs -i podman tag {} test

echo -e '\nLoaded Image...\n'
podman images test

echo -e '\nRun "podman run -it --rm -p 8080:8080 test"\n'
