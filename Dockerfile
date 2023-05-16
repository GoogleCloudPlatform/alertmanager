ARG IMAGE_BUILD_GO=golang:1.20.4-buster
ARG IMAGE_BASE=gcr.io/distroless/static-debian10

FROM ${IMAGE_BUILD_GO} AS gobase
WORKDIR /app
COPY . ./
RUN make build

FROM ${IMAGE_BASE}
COPY --from=gobase /app/alertmanager /bin/alertmanager
COPY --from=gobase /app/amtool /bin/amtool
COPY LICENSE LICENSE
COPY NOTICE NOTICE

USER       nobody
EXPOSE     9093
VOLUME     [ "/alertmanager" ]
WORKDIR    /alertmanager
ENTRYPOINT [ "/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/alertmanager.yml", \
             "--storage.path=/alertmanager" ]
