FROM golang:1.23.1@sha256:4a3c2bcd243d3dbb7b15237eecb0792db3614900037998c2cd6a579c46888c1e AS gobase
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

FROM gke.gcr.io/gke-distroless/libc:gke_distroless_20240907.00_p0@sha256:2cdd63fbfb7bc7482f28328494c8cd6783eba0d4c1007c164a9deee3656b618b
COPY --from=gobase /app/alertmanager /bin/alertmanager
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
