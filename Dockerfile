FROM alpine:3.12

# TODO: Various optional modules are currently disabled (see output of ./configure):
# - Libwrap is disabled because tcpd.h is missing.
# - BSD Auth is disabled because bsd_auth.h is missing.
# - ...

RUN set -x \
    # Runtime dependencies.
 && apk add --no-cache \
        linux-pam \
    # Build dependencies.
 && apk add --no-cache -t .build-deps \
        build-base \
        curl \
        linux-pam-dev \
 && cd /tmp \
    # https://www.inet.no/dante/download.html
 && curl -L https://www.inet.no/dante/files/dante-1.4.2.tar.gz | tar xz \
 && cd dante-* \
    # See https://lists.alpinelinux.org/alpine-devel/3932.html
 && ac_cv_func_sched_setscheduler=no ./configure \
 && make install \
 && cd / \
    # Add an unprivileged user.
 && adduser -S -D -u 8062 -H sockd \
    # Install dumb-init (avoid PID 1 issues).
    # https://github.com/Yelp/dumb-init
 && curl -Lo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 \
 && chmod +x /usr/local/bin/dumb-init \
    # Clean up.
 && rm -rf /tmp/* \
 && apk del --purge .build-deps

# Default configuration
COPY sockd.conf /etc/

EXPOSE 1080

ENTRYPOINT ["dumb-init"]
CMD ["sockd"]
