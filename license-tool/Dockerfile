FROM golang:alpine AS base
RUN apk add --no-cache build-base
WORKDIR /src

FROM base AS build
COPY entrypoint/go.* .
RUN go mod download
COPY entrypoint/ .
RUN go build -o /out/entrypoint .

FROM alpine:latest
RUN apk update --no-cache
RUN apk upgrade --no-cache
COPY --from=build /out/entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]
CMD []
