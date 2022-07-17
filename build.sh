#!/bin/sh
set -e

# Gradle init file for Jib plugin outsite of build.gradle
cat <<'EOF'> init.gradle
initscript {
  repositories {
    maven {
      url 'https://plugins.gradle.org/m2'
    }
  }
  dependencies {
    classpath 'gradle.plugin.com.google.cloud.tools:jib-gradle-plugin:3.2.1'
  }
}
rootProject {
  afterEvaluate {
    if (!project.plugins.hasPlugin('com.google.cloud.tools.jib')) {
      project.apply plugin: com.google.cloud.tools.jib.gradle.JibPlugin
      tasks.jib.dependsOn classes
    }
  }
}
EOF

# Extra directories to add to the image
# Entrypoint script to allow custom commands
mkdir -p /tmp/extraDirectories/app
cat <<'EOF'> /tmp/extraDirectories/app/run.sh
#!/bin/sh
set -e
CLASS_PATH="$(cat /app/jib-classpath-file)"
MAIN_CLASS="$(cat /app/jib-main-class-file)"
java -XshowSettings:vm -version
exec java -cp $CLASS_PATH $MAIN_CLASS
EOF

# Build with Podman
podman run --platform=linux/amd64 -it --rm \
  -v /tmp:/tmp \
  -e GRADLE_USER_HOME=/tmp/build_cache/gradle \
  -v $PWD:/code:ro -w /code \
  docker.io/library/openjdk:11-jdk \
    sh -c '
      set -ex
      cp -r /code /home/code
      cd /home/code
      exec ./gradlew --info --init-script init.gradle jibBuildTar \
        -Djib.container.user=999:0 \
        -Djib.container.workingDirectory=/app \
        -Djib.container.entrypoint=/app/run.sh \
        -Djib.container.args= \
        -Djib.extraDirectories.paths=/tmp/extraDirectories \
        -Djib.extraDirectories.permissions=/app/run.sh=755,/app=775 \
        -Djib.from.image=docker.io/library/openjdk:11-jre \
        -Djib.from.platforms=linux/amd64 \
        -Djib.allowInsecureRegistries=true \
        -Djib.outputPaths.tar=/tmp/build_cache/jib-image.tar
    '

# Load the Jib image on Podman
printf '\nLoading Image...\n'
podman load -i /tmp/build_cache/jib-image.tar | \
  awk '{print $NF}' | \
  xargs -i podman tag {} test

printf '\nLoaded Image...\n'
podman image tree test

printf '\nRun "podman run -it --rm -p 8080:8080 test"\n\n'
