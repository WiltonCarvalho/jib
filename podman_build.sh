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
mkdir -p /var/tmp/extraDirectories/app
cat <<'EOF'> /var/tmp/extraDirectories/app/run.sh
#!/bin/sh
set -e
CLASS_PATH="$(cat /app/jib-classpath-file)"
MAIN_CLASS="$(cat /app/jib-main-class-file)"
java -XshowSettings:vm -version
exec java -cp $CLASS_PATH $MAIN_CLASS
EOF

# Build with Podman
podman run --platform=linux/amd64 -it --rm \
  -v /var/tmp:/var/tmp \
  -v $PWD:/code:ro -w /code \
  docker.io/library/openjdk:11-jdk \
    sh -c '
      set -ex
      cp -r /code /home/code
      cd /home/code
      export JAVA_HOME=/usr/local/openjdk-11
      export GRADLE_USER_HOME=/var/tmp/build_cache/gradle
      exec ./gradlew --info --init-script init.gradle jibBuildTar \
        -Djib.container.user=999:0 \
        -Djib.container.workingDirectory=/app \
        -Djib.container.entrypoint=/app/run.sh \
        -Djib.container.args= \
        -Djib.extraDirectories.paths=/var/tmp/extraDirectories \
        -Djib.extraDirectories.permissions=/app/run.sh=755,/app=775 \
        -Djib.from.image=docker.io/library/openjdk:11-jre \
        -Djib.from.platforms=linux/amd64 \
        -Djib.allowInsecureRegistries=true \
        -Djib.outputPaths.tar=/var/tmp/build_cache/jib-image.tar
    '

# Load the Jib image on Podman
printf '\nLoading Image... /var/tmp/build_cache/jib-image.tar\n'
podman load -i /var/tmp/build_cache/jib-image.tar | \
  awk '{print $NF}' | \
  xargs -i podman tag {} test

printf '\nLoaded Image...\n'
podman image tree test

printf '\nRun "podman run -it --rm -p 8080:8080 test"\n\n'
