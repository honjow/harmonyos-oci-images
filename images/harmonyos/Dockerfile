FROM ubuntu:22.04 AS sdk-unpack

ARG COMMAND_LINE_TOOLS_ARCHIVE=command-line-tools.tar.zst

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates tar zstd \
 && rm -rf /var/lib/apt/lists/*

COPY ${COMMAND_LINE_TOOLS_ARCHIVE} /tmp/command-line-tools.tar.zst

RUN mkdir -p /payload \
 && tar --zstd -xf /tmp/command-line-tools.tar.zst -C /payload \
 && test -d /payload/command-line-tools/bin \
 && test -d /payload/command-line-tools/sdk \
 && test -f /payload/command-line-tools/bin/ohpm \
 && test -f /payload/command-line-tools/bin/hvigorw \
 && test -f /payload/command-line-tools/tool/node/bin/node \
 && test -f /payload/command-line-tools/sdk/default/openharmony/native/sysroot/usr/include/linux/netfilter_ipv6/ip6t_HL.h \
 && test -f /payload/command-line-tools/sdk/default/openharmony/native/sysroot/usr/include/linux/netfilter_ipv6/ip6t_hl.h

FROM ubuntu:22.04

ARG IMAGE_SOURCE=https://github.com/honjow/harmonyos-oci-images
ARG IMAGE_DESCRIPTION="HarmonyOS command-line build environment"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates ca-certificates-java git curl unzip zip xz-utils tar bash \
      libc6 libstdc++6 libgcc-s1 libncurses6 libtinfo6 zlib1g \
      libx11-6 libxext6 libxrender1 libxtst6 libxi6 libfontconfig1 libglib2.0-0 libgl1 \
      python3 make openssh-client openjdk-17-jre-headless \
 && rm -rf /var/lib/apt/lists/*

LABEL org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="${IMAGE_DESCRIPTION}"

COPY --from=sdk-unpack /payload/command-line-tools /opt/harmonyos/command-line-tools

ENV COMMANDLINE_TOOLS_HOME=/opt/harmonyos/command-line-tools \
    DEVECO_SDK_HOME=/opt/harmonyos/command-line-tools/sdk \
    HOS_SDK_HOME=/opt/harmonyos/command-line-tools/sdk \
    OHOS_BASE_SDK_HOME=/opt/harmonyos/command-line-tools/sdk/default/openharmony \
    OHOS_SDK_HOME=/opt/harmonyos/command-line-tools/sdk/default/openharmony \
    NODE_HOME=/opt/harmonyos/command-line-tools/tool/node \
    PATH=/opt/harmonyos/command-line-tools/bin:/opt/harmonyos/command-line-tools/tool/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN chmod -R a+rX /opt/harmonyos/command-line-tools \
 && ohpm -v \
 && hvigorw --version \
 && node -v \
 && java -version \
 && printf '@ohos:registry=https://ohpm.openharmony.cn/ohpm/\nregistry=https://registry.npmjs.org/\n' > /root/.npmrc

WORKDIR /workspace
CMD ["bash"]
