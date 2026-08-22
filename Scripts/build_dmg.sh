#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="BGInfoMac"
APP_PATH="${ROOT_DIR}/${APP_NAME}.app"
APP_ICON="${ROOT_DIR}/Resources/AppIcon.icns"
VOLUME_NAME="${APP_NAME}"
FINAL_DMG="${ROOT_DIR}/${APP_NAME}-Installer.dmg"
STAGING_DIR="$(mktemp -d)"
TMP_DMG="${ROOT_DIR}/.tmp_${APP_NAME}.dmg"

if [ ! -d "$APP_PATH" ]; then
    echo "No se encontró ${APP_PATH}. Corré primero ./Scripts/build_app.sh"
    exit 1
fi

echo "==> Preparando contenido del instalador..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

if [ -f "$APP_ICON" ]; then
    cp "$APP_ICON" "$STAGING_DIR/.VolumeIcon.icns"
fi

rm -f "$TMP_DMG" "$FINAL_DMG"

echo "==> Creando imagen de disco temporal..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING_DIR" -ov -format UDRW "$TMP_DMG" >/dev/null

echo "==> Montando para acomodar la ventana del Finder..."
hdiutil attach "$TMP_DMG" -readwrite -noverify -noautoopen >/dev/null
sleep 1

if [ -f "/Volumes/${VOLUME_NAME}/.VolumeIcon.icns" ]; then
    SetFile -a C "/Volumes/${VOLUME_NAME}"
fi

if osascript <<EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 760, 480}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        try
            set position of item "${APP_NAME}.app" of container window to {140, 180}
            set position of item "Applications" of container window to {420, 180}
        end try
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
EOF
then
    echo "==> Ventana del Finder configurada."
else
    echo "==> Aviso: no se pudo personalizar la ventana del Finder (puede faltar permiso de Automatización para Terminal/osascript en Ajustes del Sistema > Privacidad y Seguridad > Automatización). El DMG se genera igual, solo que sin el acomodo prolijo de íconos."
fi

sync
sleep 1

echo "==> Desmontando..."
hdiutil detach "/Volumes/${VOLUME_NAME}" >/dev/null 2>&1 || hdiutil detach "/Volumes/${VOLUME_NAME}" -force >/dev/null

echo "==> Comprimiendo imagen final..."
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG" >/dev/null
rm -f "$TMP_DMG"
rm -rf "$STAGING_DIR"

if [ -f "$APP_ICON" ]; then
    echo "==> Aplicando el ícono al archivo .dmg..."
    ICON_TMP="$(mktemp -d)"
    cp "$APP_ICON" "${ICON_TMP}/icon.icns"
    sips -i "${ICON_TMP}/icon.icns" >/dev/null
    DeRez -only icns "${ICON_TMP}/icon.icns" > "${ICON_TMP}/icon.rsrc"
    Rez -append "${ICON_TMP}/icon.rsrc" -o "$FINAL_DMG"
    SetFile -a C "$FINAL_DMG"
    rm -rf "$ICON_TMP"
fi

echo "==> Listo: ${FINAL_DMG}"
