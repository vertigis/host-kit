FROM golang:alpine AS base
RUN apk add --no-cache build-base
WORKDIR /src

FROM base AS extract-ca-certs
COPY extract-ca-certs/go.* .
RUN go mod download
COPY extract-ca-certs/ .
RUN go build -o /out/extract-ca-certs .

FROM alpine:latest
RUN apk update --no-cache
RUN apk upgrade --no-cache
RUN apk add --no-cache bash curl openssl ca-certificates rsync
COPY --from=extract-ca-certs /out /bin
COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD []
