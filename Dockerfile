FROM alpine

RUN apk add --update curl jq && \
    rm -rf /var/cache/apk/*
COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]