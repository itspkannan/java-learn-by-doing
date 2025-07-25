#!/bin/bash

set -euo pipefail

monorepo.quarkus.init.base.files() {
  echo "📁 Creating base files..."

  cat <<EOF > .gitignore
.gradle/
build/
.idea/
out/
*.iml
*.class
*.log
*.jar
.env
.DS_Store
EOF

  cat <<EOF > .editorconfig
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
EOF

  mkdir -p .vscode
  cat <<EOF > .vscode/settings.json
{
  "java.format.enabled": true,
  "editor.formatOnSave": true
}
EOF
}

monorepo.quarkus.init.gradle.root() {
  local project_name="$1"

  cat <<EOF > settings.gradle
rootProject.name = '$project_name'
include 'commons:shared-lib'
EOF

  cat <<EOF > build.gradle
plugins {
  id 'java'
}

subprojects {
  apply plugin: 'java'
  group = 'com.example'
  version = '0.1.0'

  repositories {
    mavenCentral()
  }
}
EOF

  cat <<EOF > gradle.properties
org.gradle.jvmargs=-Xmx2G
EOF
}

monorepo.quarkus.init.common() {
  mkdir -p commons/shared-lib/src/main/java
  mkdir -p commons/shared-lib/src/test/java

  cat <<EOF > commons/shared-lib/build.gradle
apply plugin: 'java-library'

tasks.named('jar') {
  enabled = true
}

dependencies {
  testImplementation 'org.junit.jupiter:junit-jupiter:5.10.2'
  testImplementation 'org.mockito:mockito-core:5.12.0'
}
EOF
}

monorepo.quarkus.init.makefile() {
  cat <<'EOF' > Makefile
.DEFAULT_GOAL := help

help: ## 🧭 Show available commands
	@echo "\n🛠️  Available Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS=":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'

build-all: ## 🏗️ Build all modules
	./gradlew build

test-all: ## ✅ Run all tests
	./gradlew test

clean: ## 🧹 Clean all builds
	./gradlew clean
EOF
}

monorepo.quarkus.init.service() {
  cat <<'EOF' > add.service.sh
#!/bin/bash

set -e

if [[ -z "$1" ]]; then
  echo "❌ Service name is required"
  echo "Usage: ./add.service.sh <service-name>"
  exit 1
fi

SERVICE_NAME="$1"
SERVICE_DIR="services/app-$SERVICE_NAME"

if [[ ! -f .base_package ]]; then
  echo "❌ Base package not found. Please create your monorepo using monorepo.quarkus.bootstrap"
  exit 1
fi

PACKAGE_NAME=$(cat .base_package)
PACKAGE_PATH="${PACKAGE_NAME//.//}/$SERVICE_NAME"

mkdir -p "$SERVICE_DIR/src/main/java/$PACKAGE_PATH"
mkdir -p "$SERVICE_DIR/src/test/java/$PACKAGE_PATH"
mkdir -p "$SERVICE_DIR/src/main/resources"

# Update settings.gradle
if ! grep -q "include 'services:app-$SERVICE_NAME'" settings.gradle; then
  echo "include 'services:app-$SERVICE_NAME'" >> settings.gradle
fi

# build.gradle
cat <<GRADLE > "$SERVICE_DIR/build.gradle"
plugins {
  id 'java'
  id 'io.quarkus'
}

dependencies {
  implementation enforcedPlatform("io.quarkus:quarkus-bom:3.11.0.Final")
  implementation 'io.quarkus:quarkus-resteasy-reactive'
  testImplementation 'io.quarkus:quarkus-junit5'
  implementation project(':commons:shared-lib')
}

repositories {
  mavenCentral()
}
GRADLE

# Main resource
cat <<APP > "$SERVICE_DIR/src/main/java/$PACKAGE_PATH/GreetingResource.java"
package ${PACKAGE_NAME}.${SERVICE_NAME};

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;

@Path("/hello")
public class GreetingResource {
  @GET
  public String hello() {
    return "Hello from $SERVICE_NAME";
  }
}
APP

# application.properties
cat <<PROP > "$SERVICE_DIR/src/main/resources/application.properties"
quarkus.http.port=8080
quarkus.banner.enabled=false
PROP

# Dockerfile
cat <<DOCKER > "$SERVICE_DIR/Dockerfile"
FROM quay.io/quarkus/quarkus-micro-image:1.0
WORKDIR /app
COPY build/quarkus-app/ /app
ENTRYPOINT ["/app/quarkus-run.jar"]
DOCKER

# Makefile
cat <<SERVICE_MAKE > "$SERVICE_DIR/Makefile"
.DEFAULT_GOAL := help

help: ## 📖 Show available commands
	@echo "\n🔧 Available commands for $SERVICE_NAME:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' \$(MAKEFILE_LIST) | awk 'BEGIN {FS=":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", \$$1, \$$2}'

build: ## 🛠️ Build the service
	../../gradlew :services:app-$SERVICE_NAME:build

run: ## 🚀 Run the Quarkus app
	../../gradlew :services:app-$SERVICE_NAME:quarkusDev

docker-build: ## 🐳 Build Docker image
	../../gradlew :services:app-$SERVICE_NAME:build
	docker build -t $SERVICE_NAME:latest -f Dockerfile .
SERVICE_MAKE

echo "✅ Service 'app-$SERVICE_NAME' created in $SERVICE_DIR"
EOF

  chmod +x add.service.sh
}

monorepo.quarkus.bootstrap() {
  local NAME=""
  local BASE_PACKAGE=""

  for arg in "$@"; do
    case $arg in
      -n=*|--name=*)
        NAME="${arg#*=}"
        ;;
      -p=*|--package=*)
        BASE_PACKAGE="${arg#*=}"
        ;;
      *)
        echo "❌ Unknown argument: $arg"
        echo "Usage: monorepo.quarkus.bootstrap -n=<project_name> [-p=<base_package>]"
        return 1
        ;;
    esac
  done

  if [[ -z "$NAME" ]]; then
    echo "❌ Project name (-n) is required."
    return 1
  fi

  if [[ -z "$BASE_PACKAGE" ]]; then
    printf "📦 Enter the base package (e.g., com.example): "
    read -r BASE_PACKAGE
    if [[ -z "$BASE_PACKAGE" ]]; then
      echo "❌ Base package is required. Aborting."
      return 1
    fi
  fi

  mkdir -p "$NAME"
  cd "$NAME" || return 1

  echo "$BASE_PACKAGE" > .base_package

  monorepo.quarkus.init.base.files
  monorepo.quarkus.init.gradle.root "$NAME"
  monorepo.quarkus.init.common
  monorepo.quarkus.init.makefile
  monorepo.quarkus.init.service

  echo "✅ Monorepo '$NAME' created with base package '$BASE_PACKAGE'"
  echo "👉 To add services, run: ./add.service.sh <service-name>"
}
