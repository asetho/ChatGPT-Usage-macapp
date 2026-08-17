#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
version="$(tr -d '[:space:]' < "$root/VERSION")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { print -u2 "VERSION must use semantic versioning (for example 1.0.1)."; exit 1; }

output_dir="$root/dist"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/chatgpt-usage-build.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT

xcodegen generate --spec "$root/project.yml"
xcodebuild \
  -project "$root/CodexUsage.xcodeproj" \
  -scheme CodexUsage \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$build_dir/derived-data" \
  MARKETING_VERSION="$version" \
  CURRENT_PROJECT_VERSION="$version" \
  CODE_SIGNING_ALLOWED=NO \
  build

app="$build_dir/derived-data/Build/Products/Release/ChatGPT Usage.app"
[[ -d "$app" ]] || { print -u2 "Expected app bundle was not built: $app"; exit 1; }

staging="$build_dir/dmg-root"
mkdir -p "$staging"
ditto "$app" "$staging/ChatGPT Usage.app"
ln -s /Applications "$staging/Applications"

mkdir -p "$output_dir"
dmg="$output_dir/ChatGPTUsage-$version.dmg"
hdiutil create -volname "ChatGPT Usage" -srcfolder "$staging" -ov -format UDZO "$dmg"
hdiutil verify "$dmg"
print "Created $dmg"
