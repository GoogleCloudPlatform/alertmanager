# TODO(bwplotka): Move to 1.23 once ARM QEMU building is fixed https://github.com/golang/go/issues/68976
FROM golang:1.24.2@sha256:30baaea08c5d1e858329c50f29fe381e9b7d7bced11a0f5f1f69a1504cdfbf5e AS gobase
WORKDIR /app
COPY . ./
RUN mkdir /etc/alertmanager
RUN mkdir /alertmanager
RUN CGO_ENABLED=1 GOEXPERIMENT=boringcrypto \
    go build \
    -tags boring \
    -mod=vendor \
    -ldflags="-X github.com/prometheus/common/version.Version=$(cat VERSION) \
    -X github.com/prometheus/common/version.BuildDate=$(date --iso-8601=seconds)" \
    ./cmd/alertmanager
RUN CGO_ENABLED=1 GOEXPERIMENT=boringcrypto \
    go build \
    -tags boring \
    -mod=vendor \
    -ldflags="-X github.com/prometheus/common/version.Version=$(cat VERSION) \
    -X github.com/prometheus/common/version.BuildDate=$(date --iso-8601=seconds)" \
    ./cmd/amtool

FROM gke.gcr.io/gke-distroless/libc:gke_distroless_20240907.00_p0@sha256:2cdd63fbfb7bc7482f28328494c8cd6783eba0d4c1007c164a9deee3656b618b
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
