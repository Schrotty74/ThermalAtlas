#!/opt/homebrew/bin/bash
set -euo pipefail

if [[ "${THERMALATLAS_ALLOW_RELEASE_PACKAGE:-}" != "YES" ]]; then
  echo 'Release packaging requires THERMALATLAS_ALLOW_RELEASE_PACKAGE=YES.' >&2
  exit 1
fi

channel="${1:-}"
version="${2:-}"
if [[ "$channel" != "beta" && "$channel" != "final" ]] || [[ -z "$version" ]]; then
  echo "Usage: $0 beta|final VERSION" >&2
  exit 64
fi
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?(\+[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$ ]]; then
  echo 'VERSION must be a semantic version, for example 0.1.0 or 0.1.0-beta.1.' >&2
  exit 64
fi

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

case "$channel" in
  beta)
    app_name='ThermalAtlas Beta'
    app_bundle_name='ThermalAtlas Beta.app'
    artifact_name="ThermalAtlas-Beta-${version}-macos"
    build_script='./build_beta_app.sh'
    ;;
  final)
    app_name='ThermalAtlas'
    app_bundle_name='ThermalAtlas.app'
    artifact_name="ThermalAtlas-${version}-macos"
    build_script='./build_final_app.sh'
    ;;
esac

./Scripts/privacy-check.sh
THERMALATLAS_VERSION="$version" "$build_script"
app_source="Build/${channel^}/${app_bundle_name}"
[[ -d "$app_source" ]] || { echo 'App bundle was not built.' >&2; exit 1; }

release_dir="dist/releases/$channel/$version"
app_bundle="$release_dir/$app_bundle_name"
zip_file="$release_dir/$artifact_name.zip"
dmg_file="$release_dir/$artifact_name.dmg"
dmg_staging="$release_dir/DMG"

rm -rf "$release_dir"
mkdir -p "$dmg_staging"
ditto "$app_source" "$app_bundle"
# Swift toolchains may retain absolute source locations in local symbols even
# for a release build. They are not needed at runtime and must not ship.
/usr/bin/strip -S "$app_bundle/Contents/MacOS/ThermalAtlas"
# Swift can inherit an Xcode toolchain rpath. Remove only machine-local rpaths
# from the copy that will be published; the system Swift rpath remains intact.
while IFS= read -r rpath; do
  case "$rpath" in
    /Users/*|/Volumes/*|/private/*)
      /usr/bin/install_name_tool -delete_rpath "$rpath" "$app_bundle/Contents/MacOS/ThermalAtlas"
      ;;
  esac
done < <(/usr/bin/otool -l "$app_bundle/Contents/MacOS/ThermalAtlas" | /usr/bin/awk '$1 == "path" { print $2 }')
/usr/bin/codesign --force --sign - --timestamp=none "$app_bundle"
/usr/bin/codesign --verify --deep --strict "$app_bundle"

if rg -a -q '/Users/|/Volumes/|/private/' "$app_bundle/Contents/MacOS/ThermalAtlas"; then
  echo 'Release package failed: local path in binary.' >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$app_bundle" "$zip_file"
ditto "$app_bundle" "$dmg_staging/$app_bundle_name"
ln -s /Applications "$dmg_staging/Applications"
hdiutil create -volname "$app_name $version" -srcfolder "$dmg_staging" -ov -format UDZO "$dmg_file" > /dev/null
(
  cd "$release_dir"
  shasum -a 256 "$(basename "$zip_file")" > "$(basename "$zip_file").sha256"
  shasum -a 256 "$(basename "$dmg_file")" > "$(basename "$dmg_file").sha256"
)

printf '%s\n' "$zip_file" "$dmg_file" "$zip_file.sha256" "$dmg_file.sha256"
