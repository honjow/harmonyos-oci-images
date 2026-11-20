# Same SDK as 26.0-api26; add the tools that Koma currently installs per job.
FROM ghcr.io/honjow/harmonyos-build-env:26.0.0.821@sha256:ac0e97380492041a914c0db03cd379de6b3ec06bf2c5fb9cfde064d75d3e242f

LABEL org.opencontainers.image.source="https://github.com/honjow/harmonyos-oci-images" \
      org.opencontainers.image.description="HarmonyOS API 26 with native build tools"

RUN set -eux; \
    apt_options() { apt-get -o Acquire::Retries=1 -o Acquire::http::Timeout=25 -o Acquire::https::Timeout=25 "$@"; }; \
    install_tools() { \
      apt_options -o APT::Update::Error-Mode=any update && \
      apt_options install -y --no-install-recommends build-essential xxd pkg-config curl ca-certificates patch perl python3 zstd; \
    }; \
    if ! install_tools; then \
      for source in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do \
        [ -f "$source" ] || continue; \
        sed -i -E 's@https?://(archive|security)\.ubuntu\.com/ubuntu/?@http://mirrors.aliyun.com/ubuntu/@g' "$source"; \
      done; \
      install_tools; \
    fi; \
    rm -rf /var/lib/apt/lists/*; \
    for tool in cc c++ make xxd pkg-config curl patch perl python3 zstd; do command -v "$tool"; done; \
    test -s /etc/ssl/certs/ca-certificates.crt
