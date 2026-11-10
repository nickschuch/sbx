# Bakes a pinned T3 Code release into the kit. To upgrade, bump the version and
# copy the linux checksums from the release's SHA256SUMS:
# https://github.com/pingdotgg/t3code/releases
# The download runs on the build host; only the extracted files are per-arch.
FROM --platform=$BUILDPLATFORM alpine:3.22 AS build

ARG TARGETARCH
ARG T3_VERSION=0.1.8
ARG T3_SHA256_X64=b9c49dc00c23fbbc5961bdaff2d88e556d96c8dbd638c4501e2937c70650a9e5
ARG T3_SHA256_ARM64=2bffbf608eef736c5c35e3431a7e5261d0c909e33d8a8feb83ef26a3747cf8f4

RUN apk add --no-cache curl tar

RUN <<EOF
set -eu
case "$TARGETARCH" in
  amd64) arch=x64; sum="$T3_SHA256_X64" ;;
  arm64) arch=arm64; sum="$T3_SHA256_ARM64" ;;
  *) echo "unsupported architecture $TARGETARCH" >&2; exit 1 ;;
esac
archive="t3-${T3_VERSION}-linux-${arch}.tar.gz"
curl -fsSL -o "/tmp/$archive" "https://github.com/pingdotgg/t3code/releases/download/v${T3_VERSION}/$archive"
echo "$sum  /tmp/$archive" | sha256sum -c -
mkdir -p /out/opt/t3code /out/usr/local/bin
tar -xzf "/tmp/$archive" -C /out/opt/t3code --strip-components=1
ln -s /opt/t3code/t3 /out/usr/local/bin/t3
EOF

FROM scratch
COPY --from=build /out/ /
