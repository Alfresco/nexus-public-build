#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <path-to-nexus-public-pom.xml>" >&2
  exit 1
fi

POM_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED_JAVA_VERSION="$(<"$SCRIPT_DIR/../.java-version")"

if [ ! -f "$POM_PATH" ]; then
  echo "❌ Nexus POM not found at $POM_PATH" >&2
  exit 1
fi

for prop in maven.compiler.release maven.compiler.source maven.compiler.target; do
  value=$(sed -n "s|.*<$prop>\([0-9]*\)</$prop>.*|\1|p" "$POM_PATH" | head -n 1)
  if [ -z "$value" ]; then
    echo "❌ Could not find <$prop> in $POM_PATH — upstream may have restructured its Java version properties." >&2
    exit 1
  fi
  if [ "$value" != "$EXPECTED_JAVA_VERSION" ]; then
    echo "❌ Upstream now targets Java $value (<$prop>) but this repo is pinned to Java $EXPECTED_JAVA_VERSION via .java-version." >&2
    echo "   Update .java-version, the Dockerfile base image and the devcontainer before building against this ref." >&2
    exit 1
  fi
done
echo "✅ Upstream Java target ($EXPECTED_JAVA_VERSION) matches .java-version"

ACTUAL_JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ "$ACTUAL_JAVA_VERSION" != "$EXPECTED_JAVA_VERSION" ]; then
  echo "❌ Running Java $ACTUAL_JAVA_VERSION but .java-version pins $EXPECTED_JAVA_VERSION." >&2
  exit 1
fi
echo "✅ Running Java $ACTUAL_JAVA_VERSION matches .java-version"
