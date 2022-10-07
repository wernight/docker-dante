FROM alpine:latest

RUN apk add --no-cache dante-server

COPY sockd.conf /etc/

EXPOSE 1080

CMD ["sockd", "-f", "/etc/sockd.conf", "-N", "2"]
