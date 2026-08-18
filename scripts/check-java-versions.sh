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

# maven.compiler.release/source/target pin the bytecode *target*, which is independent
# of the build JDK upstream's maven-enforcer-plugin requireJavaVersion rule enforces —
# a newer JDK can compile older bytecode via --release, so the two numbers may differ.
# Maven already fails loudly on its own if requireJavaVersion isn't met, so this only
# reports the bytecode target for visibility.
for prop in maven.compiler.release maven.compiler.source maven.compiler.target; do
  escaped_prop=$(printf '%s' "$prop" | sed 's/\./\\./g')
  value=$(sed -n "s|.*<$escaped_prop>\([0-9]*\)</$escaped_prop>.*|\1|p" "$POM_PATH" | head -n 1)
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
