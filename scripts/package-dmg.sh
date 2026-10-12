#!/usr/bin/env bash
set -euo pipefail

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

VERSION="${1:-1.0}"
SCHEME="PrivacyScreen"
CONFIGURATION="Release"
BUILD_DIR="${PROJECT_ROOT}/build"
DIST_DIR="${PROJECT_ROOT}/dist"
STAGE_DIR="${BUILD_DIR}/dmg_stage"
DMG_FILE="${DIST_DIR}/PrivacyScreen-v${VERSION}.dmg"

echo "==> Building PrivacyScreen (v${VERSION})..."
mkdir -p "${DIST_DIR}" "${BUILD_DIR}"
rm -rf "${STAGE_DIR}"

xcodebuild \
    -project "${PROJECT_ROOT}/PrivacyScreen.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean build

APP_PATH="${BUILD_DIR}/DerivedData/Build/Products/${CONFIGURATION}/PrivacyScreen.app"

if [ ! -d "${APP_PATH}" ]; then
    echo "Error: Built application not found at ${APP_PATH}"
    exit 1
fi

echo "==> Applying ad-hoc signature for local execution..."
codesign --force --deep -s - "${APP_PATH}"

echo "==> Staging DMG payload..."
mkdir -p "${STAGE_DIR}"
cp -R "${APP_PATH}" "${STAGE_DIR}/"
ln -s /Applications "${STAGE_DIR}/Applications"

echo "==> Creating compressed DMG..."
rm -f "${DMG_FILE}"
hdiutil create \
    -volname "PrivacyScreen" \
    -srcfolder "${STAGE_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_FILE}"

rm -rf "${STAGE_DIR}"

echo "==> Generating SHA-256 checksum..."
shasum -a 256 "${DMG_FILE}" > "${DMG_FILE}.sha256"

echo ""
echo "=========================================="
echo " Packaging complete!"
echo " DMG:      ${DMG_FILE}"
echo " Checksum: $(cat "${DMG_FILE}.sha256")"
echo "=========================================="
