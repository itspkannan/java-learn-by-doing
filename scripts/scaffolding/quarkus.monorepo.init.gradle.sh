#!/bin/bash

set -euo pipefail

# Create base project structure
create.monorepo.quarkus() {
  local NAME="$1"
  mkdir -p "$NAME"
  cd "$NAME"
  mkdir -p services
  echo ".gradle/" > .gitignore
  echo "✅ Created monorepo '$NAME'"
}

add.service.script.quarkus() {
  cat <<'EOF' > add.service.sh
#!/bin/bash
set -euo pipefail

SERVICE_NAME="$1"
if [[ -z "$SERVICE_NAME" ]]; then
  echo "Usage: ./add.service.sh <service-name>"
  exit 1
fi

cd services
mkdir -p "app-${SERVICE_NAME}"
cd "app-${SERVICE_NAME}"

gradle init --type java-application --dsl groovy --project-name "app-${SERVICE_NAME}" --package "org.example.${SERVICE_NAME}" --test-framework junit

# Replace build.gradle with minimal Quarkus setup
cat <<G > build.gradle
plugins {
    id 'java'
    id 'io.quarkus'
}

group = 'org.example'
version = '1.0.0-SNAPSHOT'

repositories {
    mavenCentral()
}

dependencies {
    implementation enforcedPlatform("io.quarkus:quarkus-bom:3.11.0.Final")
    testImplementation 'io.quarkus:quarkus-junit5'
}
G

mkdir -p src/main/java/org/example/${SERVICE_NAME}
cat <<MAIN > src/main/java/org/example/${SERVICE_NAME}/Main.java
package org.example.${SERVICE_NAME};

public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from ${SERVICE_NAME}");
    }
}
MAIN

echo "✅ Service 'app-${SERVICE_NAME}' created."
EOF

  chmod +x add.service.sh
  echo "✅ add.service.sh added. Use it with ./add.service.sh my-service"
}
