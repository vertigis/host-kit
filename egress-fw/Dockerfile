FROM alpine:latest
RUN apk --no-cache update
RUN apk --no-cache upgrade
RUN apk --no-cache add bash iptables
COPY /entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "sleep", "infinity" ]
