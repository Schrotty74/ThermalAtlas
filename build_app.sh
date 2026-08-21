#!/opt/homebrew/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
channel="${APP_BUILD_CHANNEL:-dev}"

case "$channel" in
  dev)
    app_name="ThermalAtlas Dev"
    bundle_identifier="io.github.schrotty74.thermalatlas.dev"
    configuration="debug"
    ;;
  beta)
    app_name="ThermalAtlas Beta"
    bundle_identifier="io.github.schrotty74.thermalatlas.beta"
    # Beta artifacts are public packages. A release build avoids embedding
    # machine-local debug paths while retaining an isolated beta cache.
    configuration="release"
    ;;
  final)
    app_name="ThermalAtlas"
    bundle_identifier="io.github.schrotty74.thermalatlas"
    configuration="release"
    ;;
  *)
    printf 'Unknown APP_BUILD_CHANNEL: %s\n' "$channel" >&2
    exit 64
    ;;
esac

app_bundle="$project_root/Build/${channel^}/${app_name}.app"
contents_dir="$app_bundle/Contents"
asset_catalog="$project_root/Resources/Assets.xcassets"
scratch_path="$project_root/.build/$channel"

cd "$project_root"
swift build -c "$configuration" --scratch-path "$scratch_path" --product ThermalAtlas

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp "$scratch_path/$configuration/ThermalAtlas" "$contents_dir/MacOS/ThermalAtlas"
cp "$project_root/Resources/Dev-Info.plist" "$contents_dir/Info.plist"
/usr/bin/plutil -replace CFBundleDisplayName -string "$app_name" "$contents_dir/Info.plist"
/usr/bin/plutil -replace CFBundleName -string "$app_name" "$contents_dir/Info.plist"
/usr/bin/plutil -replace CFBundleIdentifier -string "$bundle_identifier" "$contents_dir/Info.plist"
if [[ -n "${THERMALATLAS_VERSION:-}" ]]; then
  /usr/bin/plutil -replace CFBundleShortVersionString -string "$THERMALATLAS_VERSION" "$contents_dir/Info.plist"
  /usr/bin/plutil -replace CFBundleVersion -string "${THERMALATLAS_BUILD_NUMBER:-1}" "$contents_dir/Info.plist"
fi
/usr/bin/xcrun actool "$asset_catalog" \
  --compile "$contents_dir/Resources" \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$contents_dir/AssetCatalog-Info.plist" > /dev/null
rm -f "$contents_dir/AssetCatalog-Info.plist" "$contents_dir/Resources/ThermalAtlas.icns"
printf 'APPL????' > "$contents_dir/PkgInfo"
/usr/bin/codesign --force --sign - --timestamp=none "$app_bundle"
/usr/bin/touch "$app_bundle"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app_bundle"

printf '%s\n' "$app_bundle"
