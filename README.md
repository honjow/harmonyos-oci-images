# HarmonyOS OCI Images

Reusable OCI image definitions for HarmonyOS / DevEco command-line build environments.

Current image target:

- `ghcr.io/honjow/harmonyos-build-env:6.1.1.280`
- `ghcr.io/honjow/harmonyos-build-env:6.1-api24`
- DevEco command-line tools: `6.1.1.280`
- HarmonyOS SDK: `6.1.1 Release`, API 24
- ohpm: `6.1.2.268`
- hvigor: `6.24.2`
- Node.js: `v18.20.1`

The SDK payload is not committed. Upload a release asset named like
`command-line-tools-6.1.1.280.tar.zst` that expands to `command-line-tools/`,
then run the `Build HarmonyOS OCI image` workflow.

The workflow labels the image source as this repository.
