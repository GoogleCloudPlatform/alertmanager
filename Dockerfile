ARG IMAGE_BUILD_GO=google-go.pkg.dev/golang:1.20.14@sha256:6f86d8a81ff191bee8d3ff8b4c193889560b4ca15df373d5084953c5c860190f
ARG IMAGE_BASE=gke.gcr.io/gke-distroless/libc@sha256:4f834e207f2721977094aeec4c9daee7032c5daec2083c0be97760f4306e4f88

FROM ${IMAGE_BUILD_GO} AS gobase
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

FROM ${IMAGE_BASE}
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
