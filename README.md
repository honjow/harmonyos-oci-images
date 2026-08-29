# HarmonyOS OCI Images

Reusable OCI image definitions for HarmonyOS / DevEco command-line build environments.

Current image target:

- `ghcr.io/honjow/harmonyos-build-env:26.0.0.821`
- `ghcr.io/honjow/harmonyos-build-env:26.0-api26`
- DevEco command-line tools: `26.0.0.821`
- HarmonyOS SDK: `HarmonyOS 26.0.0 Release`, API 26 Release
- ohpm: `26.0.0.630`
- hvigor: `6.26.4`
- Node.js: `v24.14.1`

The SDK payload is not committed. Upload a release asset named like
`command-line-tools-26.0.0.821.tar.zst` that expands to `command-line-tools/`,
then run the `Build HarmonyOS OCI image` workflow.

The workflow labels the image source as this repository.

For the complete macOS preparation, checksum, local validation, release, and
downstream acceptance process, see [Publishing a HarmonyOS build image from
macOS](docs/RELEASING.md).
