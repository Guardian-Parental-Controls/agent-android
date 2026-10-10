#!/usr/bin/env bash
set -euo pipefail

# Build and stage the release APK plus signature-checksum sidecar.
# Usage: package-release.sh <tag> <output-dir>
# Requires ANDROID_HOME, signing env vars, and google-services.json for release builds.

TAG="${1:?release tag required (e.g. v1.0.0)}"
OUT_DIR="${2:?output directory required}"
mkdir -p "$OUT_DIR"

export GUARDIAN_AGENT_VERSION="$TAG"
./gradlew assembleRelease --no-daemon

APK_SRC="app/build/outputs/apk/release/app-release.apk"
[[ -f "$APK_SRC" ]] || {
    echo "error: release APK not found at $APK_SRC" >&2
    exit 1
}

APK_NAME="guardian-android-agent-${TAG}.apk"
APK_DEST="${OUT_DIR}/${APK_NAME}"
cp "$APK_SRC" "$APK_DEST"
scripts/android-signature-checksum.sh "$APK_DEST" > "${APK_DEST%.apk}.signature-checksum"
echo "Packaged ${APK_DEST}"
