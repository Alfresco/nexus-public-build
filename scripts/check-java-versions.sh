#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <path-to-nexus-public-pom.xml>" >&2
  exit 1
fi

POM_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PINNED_JAVA_VERSION="$(<"$SCRIPT_DIR/../.java-version")"

if [ ! -f "$POM_PATH" ]; then
  echo "❌ Nexus POM not found at $POM_PATH" >&2
  exit 1
fi

# Upstream's maven-enforcer-plugin enforce-environment execution pins the minimum
# JDK needed to *build* the project. This is independent of maven.compiler.release
# below, which pins the bytecode *target* — a newer JDK can compile older bytecode
# via --release, so the two numbers are allowed to differ.
REQUIRE_JAVA_RANGE=$(sed -n '/<requireJavaVersion>/,/<\/requireJavaVersion>/{
s|.*<version>\([^<]*\)</version>.*|\1|p
}' "$POM_PATH" | head -n 1)
REQUIRED_MIN_JAVA=$(grep -oE '[0-9]+' <<< "$REQUIRE_JAVA_RANGE" | head -n 1)
if [ -z "$REQUIRED_MIN_JAVA" ]; then
  echo "❌ Could not find a <requireJavaVersion><version> minimum in $POM_PATH — upstream may have restructured its enforcer rules." >&2
  exit 1
fi

if [ "$PINNED_JAVA_VERSION" -lt "$REQUIRED_MIN_JAVA" ]; then
  echo "❌ Upstream now requires Java >= $REQUIRED_MIN_JAVA to build (enforcer requireJavaVersion $REQUIRE_JAVA_RANGE) but this repo is pinned to Java $PINNED_JAVA_VERSION via .java-version." >&2
  echo "   Update .java-version and the devcontainer before building against this ref." >&2
  exit 1
fi
echo "✅ Upstream's minimum build JDK (requireJavaVersion $REQUIRE_JAVA_RANGE) is satisfied by .java-version ($PINNED_JAVA_VERSION)"

for prop in maven.compiler.release maven.compiler.source maven.compiler.target; do
  value=$(sed -n "s|.*<$prop>\([0-9]*\)</$prop>.*|\1|p" "$POM_PATH" | head -n 1)
  if [ -z "$value" ]; then
    echo "❌ Could not find <$prop> in $POM_PATH — upstream may have restructured its Java version properties." >&2
    exit 1
  fi
  echo "ℹ️  Upstream targets Java $value bytecode (<$prop>) — check the Dockerfile base image still matches if this changes."
done

ACTUAL_JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ "$ACTUAL_JAVA_VERSION" != "$PINNED_JAVA_VERSION" ]; then
  echo "❌ Running Java $ACTUAL_JAVA_VERSION but .java-version pins $PINNED_JAVA_VERSION." >&2
  exit 1
fi
echo "✅ Running Java $ACTUAL_JAVA_VERSION matches .java-version"
