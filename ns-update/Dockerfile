FROM alpine:latest
RUN apk --no-cache update
RUN apk --no-cache upgrade
RUN apk --no-cache add bash bind-tools krb5
COPY /entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD []