#!/opt/homebrew/bin/bash
set -euo pipefail

channel="${1:-}"
version="${2:-}"
mode="${3:---package}"
if [[ "$channel" != "beta" && "$channel" != "final" ]] || [[ -z "$version" ]]; then
  echo "Usage: $0 beta|final VERSION [--check|--package|--publish]" >&2
  exit 64
fi
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?(\+[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$ ]]; then
  echo 'VERSION must be a semantic version, for example 0.1.1 or 0.1.1-beta.1.' >&2
  exit 64
fi
if [[ "$mode" != '--check' && "$mode" != '--package' && "$mode" != '--publish' ]]; then
  echo 'Choose --check, --package or --publish.' >&2
  exit 64
fi
if [[ "$mode" != '--check' && "${THERMALATLAS_ALLOW_RELEASE_PACKAGE:-}" != 'YES' ]]; then
  echo 'Release packaging requires THERMALATLAS_ALLOW_RELEASE_PACKAGE=YES.' >&2
  exit 1
fi

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

release_header="## $version"
release_notes="$(awk -v header="$release_header" '
  $0 == header { in_section = 1; next }
  in_section && /^## / { exit }
  in_section { print }
' CHANGELOG.md)"
if [[ -z "${release_notes//[[:space:]]/}" ]]; then
  echo "Release check: CHANGELOG.md has no notes for $version. Correct the documentation, then retry." >&2
  exit 1
fi

for manual in MANUAL.md MANUAL.de.md; do
  if [[ ! -f "$manual" ]] || ! rg -F -q "$version" "$manual"; then
    echo "Release check: $manual is missing or does not name $version. Correct it, then retry." >&2
    exit 1
  fi
done

command -v pdftotext >/dev/null || { echo 'Release check needs pdftotext.' >&2; exit 1; }
for pdf in Documentation/ThermalAtlas-User-Manual-EN.pdf Documentation/ThermalAtlas-Handbuch-DE.pdf; do
  if [[ ! -s "$pdf" ]] || [[ -z "$(pdftotext "$pdf" -)" ]]; then
    echo "Release check: $pdf is missing or has no readable text. Correct it, then retry." >&2
    exit 1
  fi
done

# Added, Changed and Improved entries need substantive updates in both manuals
# and PDFs. A version-only change does not count as a documentation update.
if printf '%s\n' "$release_notes" | rg -q '^### (Added|Changed|Improved)'; then
  previous_tag="$(git describe --tags --abbrev=0 --exclude="v$version" HEAD 2>/dev/null || true)"
  if [[ -n "$previous_tag" ]]; then
    for manual in MANUAL.md MANUAL.de.md; do
      if git cat-file -e "$previous_tag:$manual" 2>/dev/null; then
        previous_text="$(git show "$previous_tag:$manual" | sed -E 's/[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.+-]+)?/VERSION/g')"
        current_text="$(sed -E 's/[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.+-]+)?/VERSION/g' "$manual")"
        if [[ "$previous_text" == "$current_text" ]]; then
          echo "Release check: $manual changed only its version since $previous_tag. Explain the new behavior, then retry." >&2
          exit 1
        fi
      fi
    done
    for pdf in Documentation/ThermalAtlas-User-Manual-EN.pdf Documentation/ThermalAtlas-Handbuch-DE.pdf; do
      if git cat-file -e "$previous_tag:$pdf" 2>/dev/null; then
        previous_text="$(git show "$previous_tag:$pdf" | pdftotext - -)"
        current_text="$(pdftotext "$pdf" -)"
        if [[ "$previous_text" == "$current_text" ]]; then
          echo "Release check: $pdf has no new readable content since $previous_tag. Update it, then retry." >&2
          exit 1
        fi
      fi
    done
  fi
fi

./Scripts/privacy-check.sh
if [[ "$mode" == '--check' ]]; then
  echo "Release check passed for $channel $version."
  exit 0
fi

if [[ "$mode" == '--publish' ]]; then
  command -v gh >/dev/null || { echo 'GitHub CLI is required for publication. Install or enable it, then retry.' >&2; exit 1; }
  expected_branch="$channel"
  [[ "$channel" == 'final' ]] && expected_branch='main'
  if [[ "$(git branch --show-current)" != "$expected_branch" ]]; then
    echo "Release publication must run on $expected_branch. Switch to the correct branch, then retry." >&2
    exit 1
  fi
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo 'Commit the reviewed release changes before publication, then retry.' >&2
    exit 1
  fi
  swift test -c debug
fi

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

"$build_script"
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
/usr/bin/strip -S "$app_bundle/Contents/MacOS/ThermalAtlas"
while IFS= read -r rpath; do
  case "$rpath" in
    /Users/*|/Volumes/*|/private/*) /usr/bin/install_name_tool -delete_rpath "$rpath" "$app_bundle/Contents/MacOS/ThermalAtlas" ;;
  esac
done < <(/usr/bin/otool -l "$app_bundle/Contents/MacOS/ThermalAtlas" | /usr/bin/awk '$1 == "path" { print $2 }')
/usr/bin/codesign --force --sign - --timestamp=none "$app_bundle"
/usr/bin/codesign --verify --deep --strict "$app_bundle"

if rg -a -q '/Users/|/Volumes/|/private/' "$app_bundle/Contents/MacOS/ThermalAtlas"; then
  echo 'Release package failed: local path in binary.' >&2
  exit 1
fi

ditto -c -k --norsrc --keepParent "$app_bundle" "$zip_file"
ditto "$app_bundle" "$dmg_staging/$app_bundle_name"
ln -s /Applications "$dmg_staging/Applications"
hdiutil create -volname "$app_name $version" -srcfolder "$dmg_staging" -ov -format UDZO "$dmg_file" > /dev/null
(
  cd "$release_dir"
  shasum -a 256 "$(basename "$zip_file")" > "$(basename "$zip_file").sha256"
  shasum -a 256 "$(basename "$dmg_file")" > "$(basename "$dmg_file").sha256"
)

printf '%s\n' "$zip_file" "$dmg_file" "$zip_file.sha256" "$dmg_file.sha256"

if [[ "$mode" == '--publish' ]]; then
  (cd "$release_dir" && shasum -a 256 -c "$(basename "$zip_file").sha256" "$(basename "$dmg_file").sha256")
  tag="v$version"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    if [[ "$(git rev-list -n 1 "$tag")" != "$(git rev-parse HEAD)" ]]; then
      echo "Tag $tag points to another commit. Resolve this before retrying." >&2
      exit 1
    fi
  else
    git tag "$tag"
  fi
  git push origin "$expected_branch"
  git push origin "$tag"
  release_options=(--title "ThermalAtlas ${channel^} $version" --notes "$release_notes" --target "$expected_branch")
  [[ "$channel" == 'beta' ]] && release_options+=(--prerelease)
  if ! gh release view "$tag" --json url >/dev/null 2>&1; then
    gh release create "$tag" "$dmg_file" "$dmg_file.sha256" "$zip_file" "$zip_file.sha256" "${release_options[@]}"
  fi
  expected_assets="$(printf '%s\n' "$(basename "$dmg_file")" "$(basename "$dmg_file").sha256" "$(basename "$zip_file")" "$(basename "$zip_file").sha256" | sort)"
  actual_assets="$(gh release view "$tag" --json assets --jq '.assets[].name' | sort)"
  if [[ "$actual_assets" != "$expected_assets" ]]; then
    echo "GitHub release $tag has incomplete assets. Correct them, then retry." >&2
    exit 1
  fi
  release_state="$(gh release view "$tag" --json isDraft,isPrerelease,assets --jq '[.isDraft, .isPrerelease, ([.assets[].state] | all(. == "uploaded"))] | join(" ")')"
  expected_state='false false true'
  [[ "$channel" == 'beta' ]] && expected_state='false true true'
  if [[ "$release_state" != "$expected_state" ]]; then
    echo "GitHub release $tag has an unexpected draft, prerelease or upload state. Correct it, then retry." >&2
    exit 1
  fi
  remote_head="$(git ls-remote origin "refs/heads/$expected_branch" | awk '{ print $1 }')"
  remote_tag="$(git ls-remote origin "refs/tags/$tag" | awk '{ print $1 }')"
  if [[ "$remote_head" != "$(git rev-parse HEAD)" ]] || [[ "$remote_tag" != "$(git rev-parse "$tag")" ]]; then
    echo 'GitHub branch or tag does not match the local release commit. Correct it, then retry.' >&2
    exit 1
  fi
  gh release view "$tag" --json url --jq '.url'
fi
