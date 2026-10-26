# Repository instructions

## Overview

Builds Sonatype Nexus Repository OSS from the [sonatype/nexus-public](https://github.com/sonatype/nexus-public) source and publishes it as release tarballs and a multi-arch (amd64/arm64) image at `ghcr.io/alfresco/nexus-public-build:<nexus version>`. Downstream, `Alfresco/nexus3-dynamodb-realm` builds `FROM` this image, and the archive Nexus stack in `Alfresco/terraform-alfresco-nexus` deploys that result.

This repo is a fork of `ChristianHoesel/nexus-public-build`. It holds no Nexus source of its own: CI checks out a `release-<version>` tag of nexus-public at build time.

## Layout

- `.github/workflows/build-nexus.yml` - the only workflow: pre-commit, Maven build, integration test (starts Nexus from the tarball and waits for the status endpoint), GitHub release, and Docker image build/push.
- `Dockerfile` - runtime image. Expects `nexus-<version>.tar.gz` in the build context and `NEXUS_VERSION` as a build arg.
- `.java-version` - build JDK major version, used by `actions/setup-java` and `build-local.sh`.
- `scripts/check-java-versions.sh` - fails if the running JDK doesn't match `.java-version`, or if the `Dockerfile` runtime image doesn't match upstream's `maven.compiler.release`.
- `build-local.sh` - local equivalent of the CI build.
- `README.md`, `DOCKER.md` - build and image usage docs.

## Commands

```sh
# Build locally (clones nexus-public at the given tag)
./build-local.sh release-<version>

# Run all pre-commit hooks
pre-commit run --all-files
```

## Bumping the Nexus version

- The default nexus-public tag lives in `build-nexus.yml` (`workflow_dispatch` default and the `||` fallbacks used by push and PR builds). Pushes to `main` build that default, so changing it is what publishes a new image tag.
- Image and release tags use the bare version (`3.97.2-02`), without the `release-` prefix.
- Check `maven.compiler.release` in the new tag's root `pom.xml`. If it changes, update the `Dockerfile` base image to match; `check-java-versions.sh` enforces this in CI.

## Conventions

- Third-party actions are SHA-pinned with a version comment (enforced by the `gha-sha-convert` pre-commit hook). `Alfresco/alfresco-build-tools` actions may use release tags.
- The `Dockerfile` base image is pinned by digest. The build JDK (`.java-version`) and the runtime JRE (`Dockerfile`) are independent: the runtime must match upstream's bytecode target, not the build JDK.
- Dependabot ignores major `eclipse-temurin` bumps for the same reason.
