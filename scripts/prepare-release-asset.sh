#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/prepare-release-asset.sh \
    --archive /path/to/official-linux-command-line-tools.zip \
    --version <command-line-tools-version> \
    [--source-sha256 <sha256-from-huawei>] \
    [--output-dir dist]

The input must be the Linux Command Line Tools archive even when this script is
run on macOS. Extraction and repacking run inside a linux/amd64 Docker
container so case-distinct Linux SDK paths are preserved. The result is a
GitHub Release asset named:

  command-line-tools-<version>.tar.zst
EOF
}

archive=""
version=""
source_sha256=""
output_dir="dist"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive)
      archive="${2:-}"
      shift 2
      ;;
    --version)
      version="${2:-}"
      shift 2
      ;;
    --source-sha256)
      source_sha256="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$archive" || -z "$version" ]]; then
  usage >&2
  exit 2
fi

if [[ ! -f "$archive" ]]; then
  echo "Archive not found: $archive" >&2
  exit 1
fi

if [[ ! "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]; then
  echo "Invalid version: $version" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Required command not found: docker" >&2
  exit 1
fi

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

source_actual_sha256="$(sha256_file "$archive")"
if [[ -n "$source_sha256" && "$source_actual_sha256" != "$source_sha256" ]]; then
  echo "Source archive SHA-256 mismatch" >&2
  echo "expected: $source_sha256" >&2
  echo "actual:   $source_actual_sha256" >&2
  exit 1
fi

asset_name="command-line-tools-$version.tar.zst"
archive_name="$(basename "$archive")"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
asset_path="$output_dir/$asset_name"
rm -f "$asset_path" "$asset_path.partial"

docker_input_dir="$(mktemp -d "${TMPDIR:-/tmp}/harmonyos-oci-docker-input.XXXXXX")"
trap 'rm -rf "$docker_input_dir"' EXIT
cp "$archive" "$docker_input_dir/$archive_name"

docker run --rm \
  --platform linux/amd64 \
  --mount "type=bind,src=$docker_input_dir,dst=/input,readonly" \
  --mount "type=bind,src=$output_dir,dst=/output" \
  --env "ARCHIVE_NAME=$archive_name" \
  --env "ASSET_NAME=$asset_name" \
  ubuntu:22.04 \
  bash -euo pipefail -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends unzip zstd >/dev/null

    mkdir -p /work/extracted
    case "$ARCHIVE_NAME" in
      *.zip)
        unzip -q "/input/$ARCHIVE_NAME" -d /work/extracted
        ;;
      *.tar.gz|*.tgz|*.tar.xz|*.tar.zst|*.tar)
        tar -xf "/input/$ARCHIVE_NAME" -C /work/extracted
        ;;
      *)
        echo "Unsupported archive type: $ARCHIVE_NAME" >&2
        exit 1
        ;;
    esac

    tools_dir="$(find /work/extracted -type d -name command-line-tools -print -quit)"
    if [[ -z "$tools_dir" ]]; then
      echo "The archive does not contain a command-line-tools directory" >&2
      exit 1
    fi

    for required_path in bin sdk tool/node/bin; do
      test -d "$tools_dir/$required_path" || {
        echo "Command Line Tools layout is missing: $required_path" >&2
        exit 1
      }
    done
    test -f "$tools_dir/bin/ohpm"
    test -f "$tools_dir/bin/hvigorw"
    test -f "$tools_dir/tool/node/bin/node"
    test -f "$tools_dir/sdk/default/openharmony/native/sysroot/usr/include/linux/netfilter_ipv6/ip6t_HL.h"
    test -f "$tools_dir/sdk/default/openharmony/native/sysroot/usr/include/linux/netfilter_ipv6/ip6t_hl.h"

    find "$tools_dir" -name .DS_Store -delete
    tar -cf - -C "$(dirname "$tools_dir")" command-line-tools \
      | zstd -q -T0 -19 -f -o "/output/$ASSET_NAME.partial"
    mv "/output/$ASSET_NAME.partial" "/output/$ASSET_NAME"
    chmod 0644 "/output/$ASSET_NAME"
  '

asset_sha256="$(sha256_file "$asset_path")"
asset_size="$(wc -c < "$asset_path" | tr -d ' ')"
checksum_path="$asset_path.sha256"
printf '%s  %s\n' "$asset_sha256" "$asset_name" > "$checksum_path"

cat <<EOF
Prepared HarmonyOS Command Line Tools release asset
source:        $archive
source sha256: $source_actual_sha256
asset:         $asset_path
asset bytes:   $asset_size
asset sha256:  $asset_sha256
checksum:      $checksum_path
EOF
