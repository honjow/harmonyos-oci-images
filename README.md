# HarmonyOS OCI Images

Reusable OCI image definitions for HarmonyOS / DevEco command-line build environments.

Current image target:

- `ghcr.io/honjow/harmonyos-build-env:26.0.0.461`
- `ghcr.io/honjow/harmonyos-build-env:26.0-api26`
- DevEco command-line tools: `26.0.0.461`
- HarmonyOS SDK: `HarmonyOS 26.0.0 Beta1`, API 26 Beta1
- ohpm: `26.0.0.410`
- hvigor: `6.26.1`
- Node.js: `v24.14.1`

The SDK payload is not committed. Upload a release asset named like
`command-line-tools-26.0.0.461.tar.zst` that expands to `command-line-tools/`,
then run the `Build HarmonyOS OCI image` workflow.

The workflow labels the image source as this repository.
