## Jib Multi Arch Build
### Demo App Gradle
```
curl -fsSL https://start.spring.io/starter.tgz \
  -d dependencies=web,actuator,prometheus \
  -d javaVersion=11 \
  -d packageName=com.example \
  -d groupId=com.example \
  -d artifactId=demo-app \
  -d baseDir=demo-app \
  -d type=gradle-project | tar -xzvf -
```

### Demo App Maven
```
curl -fsSL https://start.spring.io/starter.tgz \
  -d dependencies=web,actuator,prometheus \
  -d javaVersion=11 \
  -d packageName=com.example \
  -d groupId=com.example \
  -d artifactId=demo-app \
  -d baseDir=demo-app \
  -d type=maven-project | tar -xzvf -
```

### Local Registry
```
docker run -d --rm --name registry -p 5000:5000 registry:2
```

### JDK Container
```
docker run -it --rm --net=host \
-v $PWD/demo-app:/src/app \
-w /src/app \
openjdk:11-jdk bash
```

### Build With Maven Jib
```
./mvnw --batch-mode package \
com.google.cloud.tools:jib-maven-plugin:3.2.1:build \
-Dmaven.repo.local=$PWD/build_cache/maven \
-Djib.from.image=openjdk:11-jre \
-Djib.from.platforms=linux/amd64,linux/arm64 \
-Djib.allowInsecureRegistries=true \
-Djib.to.image=127.0.0.1:5000/demo-app:v1
```


### Build With Gradle Jib
```
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
```
```
export GRADLE_USER_HOME=$PWD/build_cache/gradle
./gradlew --info --console=plain --init-script init.gradle jib \
-Djib.from.image=openjdk:11-jre \
-Djib.from.platforms=linux/amd64,linux/arm64 \
-Djib.allowInsecureRegistries=true \
-Djib.to.image=127.0.0.1:5000/demo-app:v1
```

### Image Poll with Docker
```
docker pull --platform arm64 127.0.0.1:5000/demo-app:v1
```
```
docker pull --platform amd64 127.0.0.1:5000/demo-app:v1
```

### Image Poll with Skopeo
```
skopeo copy --all --src-tls-verify=false \
docker://127.0.0.1:5000/demo-app:v1 oci-archive:my-oci-image.tar
```
```
skopeo inspect --raw oci-archive:my-oci-image.tar | \
jq -r '.manifests[].platform.architecture'
```
```
skopeo inspect oci-archive:my-oci-image.tar --override-arch=amd64
```
```
skopeo inspect oci-archive:my-oci-image.tar --override-arch=arm64
```
```
skopeo copy --override-arch=amd64 --src-tls-verify=false \
docker://127.0.0.1:5000/demo-app:v1 \
docker-archive:my-docker-image-amd64.tar
```
```
skopeo inspect docker-archive:my-docker-image-amd64.tar
```
```
skopeo copy --override-arch=arm64 --src-tls-verify=false \
docker://127.0.0.1:5000/demo-app:v1 \
docker-archive:my-docker-image-arm64.tar
```
```
skopeo inspect docker-archive:my-docker-image-arm64.tar
```

### Load Image from Tar
```
docker load -i my-docker-image-amd64.tar | \
awk -F':' '{print $NF}' | \
xargs -i docker tag {} my-docker-image
```
```
docker run -it --rm my-docker-image
```
