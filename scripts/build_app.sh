#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_DIR}"

APP_NAME="BoardWatch"
BUILD_DIR="${PROJECT_DIR}/.build/release"
APP_BUNDLE="${PROJECT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 Building ${APP_NAME} in release mode..."
swift build -c release

echo "📦 Packaging ${APP_NAME}.app..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist
cp "${PROJECT_DIR}/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Code sign ad-hoc so macOS allows running without Gatekeeper warnings
echo "🔏 Code-signing application bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Successfully built: ${APP_BUNDLE}"

if [[ "$1" == "--run" ]]; then
    echo "🚀 Launching ${APP_NAME}.app..."
    open "${APP_BUNDLE}"
fi
