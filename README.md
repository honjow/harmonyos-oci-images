# HarmonyOS OCI Images

Reusable OCI image definitions for HarmonyOS / DevEco command-line build environments.

Current image target:

- `ghcr.io/honjow/harmonyos-build-env:6.1.0.830`
- `ghcr.io/honjow/harmonyos-build-env:6.1-api23`
- DevEco command-line tools: `6.1.0.830`
- HarmonyOS SDK: `6.1.0 Release`, API 23
- ohpm: `6.1.1.830`
- hvigor: `6.23.5`
- Node.js: `v18.20.1`

The SDK payload is not committed. Upload a release asset named like
`command-line-tools-6.1.0.830.tar.zst` that expands to `command-line-tools/`,
then run the `Build HarmonyOS OCI image` workflow.

The workflow sets `org.opencontainers.image.source` to the consuming repository
(default `honjow/Next2V`) before the first publish so GitHub Packages can attach
repository workflow access correctly.
