#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="BGInfoMac"
BUILD_CONFIG="release"

echo "==> Compilando ${APP_NAME} (${BUILD_CONFIG})..."
swift build -c "${BUILD_CONFIG}"

BIN_PATH=".build/${BUILD_CONFIG}/${APP_NAME}"
if [ ! -f "$BIN_PATH" ]; then
    echo "No se encontró el binario compilado en ${BIN_PATH}"
    exit 1
fi

APP_BUNDLE="${ROOT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Armando el bundle ${APP_NAME}.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/${APP_NAME}"
cp "${ROOT_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
cp "${ROOT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
cp "${ROOT_DIR}/Resources/StatusIcon.png" "${RESOURCES_DIR}/StatusIcon.png"
cp "${ROOT_DIR}/Resources/StatusIcon@2x.png" "${RESOURCES_DIR}/StatusIcon@2x.png"

chmod +x "$MACOS_DIR/${APP_NAME}"

echo "==> Firmando ad-hoc..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Listo: ${APP_BUNDLE}"
echo "    Podés abrirla con: open \"${APP_BUNDLE}\""
