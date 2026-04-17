#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_NAME="WhisperAI"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"

CONFIG="${1:-release}"

echo "Building ${APP_NAME} (${CONFIG})…"

rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS}"

SDK_PATH=$(xcrun --show-sdk-path)

SWIFT_FLAGS="-swift-version 5 -target arm64-apple-macosx13.0 -sdk ${SDK_PATH}"
FRAMEWORKS="-framework Cocoa -framework AVFoundation -framework Carbon -framework UserNotifications -framework SwiftUI -framework Combine -framework ServiceManagement"

if [ "${CONFIG}" = "debug" ]; then
    SWIFT_FLAGS="${SWIFT_FLAGS} -Onone"   # no -g: avoids .dSYM which breaks codesign
else
    SWIFT_FLAGS="${SWIFT_FLAGS} -O"
fi

SOURCES=(
    "${PROJECT_DIR}/WhisperAI/main.swift"
    "${PROJECT_DIR}/WhisperAI/AppDelegate.swift"
    "${PROJECT_DIR}/WhisperAI/AppState.swift"
    "${PROJECT_DIR}/WhisperAI/Audio/AudioRecorder.swift"
    "${PROJECT_DIR}/WhisperAI/API/WhisperService.swift"
    "${PROJECT_DIR}/WhisperAI/API/LLMService.swift"
    "${PROJECT_DIR}/WhisperAI/Modes/Mode.swift"
    "${PROJECT_DIR}/WhisperAI/Modes/ModeManager.swift"
    "${PROJECT_DIR}/WhisperAI/UI/WhisperAIModel.swift"
    "${PROJECT_DIR}/WhisperAI/UI/MenuBarPopoverView.swift"
    "${PROJECT_DIR}/WhisperAI/UI/GeneralSettingsView.swift"
    "${PROJECT_DIR}/WhisperAI/UI/ModesSettingsView.swift"
    "${PROJECT_DIR}/WhisperAI/UI/StatusBarController.swift"
    "${PROJECT_DIR}/WhisperAI/UI/SettingsWindowController.swift"
    "${PROJECT_DIR}/WhisperAI/UI/InsertionHUD.swift"
    "${PROJECT_DIR}/WhisperAI/UI/RecordingHUD.swift"
    "${PROJECT_DIR}/WhisperAI/UI/AccessibilityOnboarding.swift"
    "${PROJECT_DIR}/WhisperAI/Services/TextInserter.swift"
    "${PROJECT_DIR}/WhisperAI/Services/HotkeyManager.swift"
    "${PROJECT_DIR}/WhisperAI/Services/SettingsManager.swift"
    "${PROJECT_DIR}/WhisperAI/Services/KeychainHelper.swift"
)

# shellcheck disable=SC2086
swiftc ${SWIFT_FLAGS} ${FRAMEWORKS} \
    -o "${MACOS}/${APP_NAME}" \
    "${SOURCES[@]}"

cp "${PROJECT_DIR}/WhisperAI/Info.plist"  "${CONTENTS}/Info.plist"

# App Icon
RESOURCES="${CONTENTS}/Resources"
mkdir -p "${RESOURCES}"
cp "${PROJECT_DIR}/WhisperAI/AppIcon.icns" "${RESOURCES}/AppIcon.icns"

# Remove resource forks/extended attributes that break codesign
xattr -cr "${APP_BUNDLE}"

# Code-Signierung mit stabilem lokalen Zertifikat.
# "WhisperAI Dev" ist ein einmalig erzeugtes selbst-signiertes Zertifikat im
# Login-Keychain — dadurch bleibt die Signatur über alle Builds hinweg gleich
# und macOS muss Keychain-Zugriff (und Accessibility) nur einmal genehmigen.
# Fallback auf Ad-hoc (-), falls das Zertifikat nicht gefunden wird.
if security find-identity -v -p codesigning | grep -q "WhisperAI Dev"; then
    SIGN_ID="WhisperAI Dev"
else
    SIGN_ID="-"
    echo "⚠️  Zertifikat 'WhisperAI Dev' nicht gefunden — Ad-hoc-Signierung wird verwendet."
fi
codesign --force --sign "${SIGN_ID}" --entitlements "${PROJECT_DIR}/WhisperAI/WhisperAI.entitlements" "${APP_BUNDLE}"
echo "✓ Code-signiert (${SIGN_ID})"

# Refresh Launch Services + Dock icon cache so the new bundle is recognized
# immediately (avoids stale hash → "app is damaged" and missing icons).
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
if [ -x "${LSREGISTER}" ]; then
    "${LSREGISTER}" -u "${APP_BUNDLE}" >/dev/null 2>&1 || true
    "${LSREGISTER}" -f "${APP_BUNDLE}" >/dev/null 2>&1 || true
fi
killall Dock >/dev/null 2>&1 || true
echo "✓ Launch Services aktualisiert"

echo "✓ Build erfolgreich: ${APP_BUNDLE}"
echo ""
echo "Starten mit:  open ${APP_BUNDLE}"
echo "Oder:         ${MACOS}/${APP_NAME}"
