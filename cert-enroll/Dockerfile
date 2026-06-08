FROM alpine:latest
RUN apk --no-cache update
RUN apk --no-cache upgrade
RUN apk --no-cache add bash certmonger dbus openssl pwgen
ENV CERT_DIR=/data/server
COPY /*.sh /*.md /
RUN chmod +x /*.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD []
