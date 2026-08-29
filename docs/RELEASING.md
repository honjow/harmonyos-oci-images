# Publishing a HarmonyOS build image from macOS

This repository publishes a Linux OCI image. Always download the **Linux
64-bit** HarmonyOS Command Line Tools archive, even when preparing the release
on macOS. A macOS archive contains host binaries that cannot run in the Ubuntu
GitHub Actions container.

## 1. Choose the compatible SDK line

Do not interpret "latest" as only the most recent download date. Record all of
the following from Huawei's download page:

- Command Line Tools version;
- HarmonyOS release and API level;
- host platform (`Linux 64-bit`);
- source archive SHA-256. Prefer Huawei's published checksum when one is
  available; otherwise compute it locally and label it as locally computed in
  the release record.

The current downstream projects NextE, NextN, and Next2V build their default
product with HarmonyOS 26 / API 26 and consume the moving image tag
`26.0-api26`. For an update within API 26, keep that moving tag and publish a
new exact tool-version tag. A different API line requires a new moving tag and
a separate review of every downstream project's `build-profile.json5`, Hvigor
model version, dependencies, and workflow image reference.

Official entrypoints:

- [Command Line Tools download center](https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos)
- [Command Line Tools setup guide](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-commandline-get-V5)

## 2. Prepare the GitHub Release asset

Keep the downloaded archive outside this Git repository. From the repository
root, run:

```bash
bash scripts/prepare-release-asset.sh \
  --archive "$HOME/Downloads/<official-linux-archive>.zip" \
  --version <command-line-tools-version> \
  --source-sha256 <official-or-locally-computed-sha256> \
  --output-dir dist
```

The script verifies the source checksum, then performs extraction and
repacking inside a `linux/amd64` Docker container. This is mandatory on the
default case-insensitive macOS filesystem: the Linux SDK contains header files
whose names differ only by letter case, and extracting them directly on macOS
silently loses one side of those pairs. The container checks the expected
`command-line-tools/` layout, removes `.DS_Store` files, and creates:

```text
dist/command-line-tools-<version>.tar.zst
dist/command-line-tools-<version>.tar.zst.sha256
```

The generated SDK payload is a release artifact. Do not commit it.

## 3. Validate the Linux image locally

Docker Desktop or OrbStack must be running. Do not extract the SDK on macOS.
Copy only the prepared asset and Dockerfile into a temporary build context;
the Dockerfile extracts it in a case-sensitive Linux build stage and builds
the same `linux/amd64` image used by GitHub Actions:

```bash
version=<command-line-tools-version>
context="$(mktemp -d)"
cp images/harmonyos/Dockerfile "$context/Dockerfile"
cp "dist/command-line-tools-$version.tar.zst" "$context/command-line-tools.tar.zst"

docker build \
  --platform linux/amd64 \
  --build-arg "IMAGE_DESCRIPTION=HarmonyOS command-line build environment $version" \
  -t "harmonyos-build-env:$version-local" \
  "$context"
```

The Dockerfile checks `ohpm`, `hvigorw`, Node.js, and Java during the build.
It also checks a known pair of case-distinct Linux SDK headers so a damaged
macOS extraction cannot pass unnoticed. Record the printed tool versions. Then
run at least one real downstream build; a tool version printout alone is not
SDK acceptance:

```bash
docker run --rm --platform linux/amd64 \
  -v /absolute/path/to/project:/workspace \
  -w /workspace \
  "harmonyos-build-env:$version-local" \
  bash -lc 'ohpm install --all && hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon'
```

Use a clean project checkout or worktree so container-owned dependency and
build outputs do not alter an active development workspace.

## 4. Create the GitHub Release

Create a release whose tag is the exact Command Line Tools version and upload
both generated files. Include the source archive SHA-256, generated asset
SHA-256, HarmonyOS/API line, and the versions printed by the image build.

Example with GitHub CLI:

```bash
version=<command-line-tools-version>
gh release create "$version" \
  "dist/command-line-tools-$version.tar.zst" \
  "dist/command-line-tools-$version.tar.zst.sha256" \
  --target main \
  --title "HarmonyOS command-line tools $version" \
  --notes-file /path/to/release-notes.md
```

## 5. Update and publish the image

Update the current defaults in these files:

- `README.md`: exact image tag and tool/SDK versions;
- `.github/workflows/build-harmonyos-image.yml`: `version`, `api_tag`,
  `sdk_asset`, and `sdk_sha256` defaults and fallbacks.

Push the reviewed change to `main`, or manually dispatch `Build HarmonyOS OCI
image` with the same four values. The workflow downloads the release asset,
verifies its SHA-256, builds the image, and pushes both tags:

```text
ghcr.io/honjow/harmonyos-build-env:<exact-version>
ghcr.io/honjow/harmonyos-build-env:<api-moving-tag>
```

Do not treat a successful asset upload as an image release. Verify the exact
workflow run and pull the exact image tag before moving on.

## 6. Downstream decision and acceptance

- Same API line: keep the existing moving tag in downstream workflows. Trigger
  each downstream build and require its real `ohpm install` plus Hvigor build
  to succeed against the newly published image.
- New API line: update each project in its own reviewed change. Do not change
  only the image tag; review `targetSdkVersion`, `compatibleSdkVersion`,
  `modelVersion`, native toolchain compatibility, and dependencies together.
- Keep the previous exact image tag available for rollback. Moving tags are
  convenience selectors, not immutable evidence of which SDK built an older
  artifact.

Current consumers:

```text
NextE   .github/workflows/build.yml  -> 26.0-api26
NextN   .github/workflows/build.yml  -> 26.0-api26
Next2V  .github/workflows/build.yml  -> 26.0-api26
```

Create one file under `docs/releases/` for every prepared version. The release
record is the durable evidence for source provenance, checksums, embedded tool
versions, local image validation, downstream acceptance, and publication
status.
