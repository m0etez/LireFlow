#!/bin/sh
# Build a Developer ID-signed, notarized DMG in dist/: `sh scripts/release.sh`
#
# One-time setup (stores an app-specific password from appleid.apple.com in the keychain):
#   xcrun notarytool store-credentials LireFlow-notary --apple-id <your Apple ID> --team-id 3RKLE28Y6U
# SKIP_NOTARIZE=1 builds and signs only (the DMG then won't pass Gatekeeper on other Macs).
set -eu
cd "$(dirname "$0")/.."

profile="${NOTARY_PROFILE:-LireFlow-notary}"
version=$(xcodebuild -project LireFlow.xcodeproj -scheme LireFlow -configuration Release -showBuildSettings 2>/dev/null \
    | awk '$1 == "MARKETING_VERSION" { print $3; exit }')
work=$(mktemp -d)
dmg="dist/LireFlow-$version.dmg"

echo "Archiving LireFlow ${version}…"
xcodebuild -project LireFlow.xcodeproj -scheme LireFlow -configuration Release \
    -archivePath "$work/LireFlow.xcarchive" -allowProvisioningUpdates -quiet archive
xcodebuild -exportArchive -archivePath "$work/LireFlow.xcarchive" -exportPath "$work/export" \
    -exportOptionsPlist scripts/ExportOptions.plist -allowProvisioningUpdates -quiet

echo "Building ${dmg}…"
mkdir "$work/dmg"
cp -R "$work/export/LireFlow.app" "$work/dmg/"
ln -s /Applications "$work/dmg/Applications"
mkdir -p dist
hdiutil create -volname "LireFlow $version" -srcfolder "$work/dmg" -format UDZO -ov -quiet "$dmg"
codesign --sign "Developer ID Application" --timestamp "$dmg"

if [ "${SKIP_NOTARIZE:-}" = 1 ]; then
    echo "Skipped notarization: $dmg is signed but not notarized."
    exit 0
fi

echo "Notarizing (usually a few minutes)…"
xcrun notarytool submit "$dmg" --keychain-profile "$profile" --wait
xcrun stapler staple "$dmg"
spctl --assess --type open --context context:primary-signature -vv "$dmg"
echo "Ready: $dmg"
