FROM --platform=$BUILDPLATFORM google-go.pkg.dev/golang:1.26.10@sha256:512fdac4a85972a5323695af8ebb41d2c7518b9fa1f230bd8066ee9b46d10a35 AS gobase
ARG TARGETOS
ARG TARGETARCH
ARG BUILDARCH
WORKDIR /app
COPY . ./
RUN mkdir -p /etc/alertmanager /alertmanager
ENV GOEXPERIMENT=boringcrypto
ENV CGO_ENABLED=1
ENV GOFIPS140=off
ENV GOTOOLCHAIN=local
ENV GOWORK=off
ENV GOARCH=${TARGETARCH}
ENV GOOS=${TARGETOS}
RUN if [ "${TARGETARCH}" = "arm64" ] && [ "${BUILDARCH}" != "arm64" ]; then \
      apt-get update && apt-get install -y --no-install-recommends \
        gcc-aarch64-linux-gnu libc6-dev-arm64-cross && \
      rm -rf /var/lib/apt/lists/*; \
      export CC=aarch64-linux-gnu-gcc; \
    elif [ "${TARGETARCH}" = "amd64" ] && [ "${BUILDARCH}" != "amd64" ]; then \
      apt-get update && apt-get install -y --no-install-recommends \
        gcc-x86-64-linux-gnu libc6-dev-amd64-cross && \
      rm -rf /var/lib/apt/lists/*; \
      export CC=x86_64-linux-gnu-gcc; \
    fi && \
    go build \
    -ldflags="-X github.com/prometheus/common/version.Version=$(cat VERSION) \
    -X github.com/prometheus/common/version.BuildDate=$(date --iso-8601=seconds)" \
    ./cmd/alertmanager && \
    go build \
    -ldflags="-X github.com/prometheus/common/version.Version=$(cat VERSION) \
    -X github.com/prometheus/common/version.BuildDate=$(date --iso-8601=seconds)" \
    ./cmd/amtool

FROM gke.gcr.io/gke-distroless/libc:gke_distroless_20260928.00_p0@sha256:521379cbafae8f38a3cc396b9abdc569872ff9c4e26e7f6dee7b564b4fd33ab3
COPY --from=gobase /app/alertmanager /bin/alertmanager
COPY --from=gobase /app/amtool /bin/amtool
COPY --from=gobase --chown=nobody:nobody /etc/alertmanager /etc/alertmanager
COPY --from=gobase --chown=nobody:nobody /alertmanager /alertmanager
COPY LICENSE LICENSE
COPY NOTICE NOTICE

USER       nobody
EXPOSE     9093
VOLUME     [ "/alertmanager" ]
WORKDIR    /alertmanager
ENTRYPOINT [ "/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/alertmanager.yml", \
             "--storage.path=/alertmanager" ]
