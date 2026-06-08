FROM curlimages/curl:latest
USER root
RUN apk update --no-cache
RUN apk upgrade --no-cache
RUN apk add --no-cache bash openssl pup
COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENTRYPOINT ["/entrypoint.sh"]
CMD []
