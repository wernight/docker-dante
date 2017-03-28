FROM debian:jessie

RUN set -x \
 && apt-get update \
    # Runtime dependencies.
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        libpam0g \
        libwrap0 \
    # Build dependencies.
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libpam0g-dev \
        libwrap0-dev \
 && mkdir /tmp/dante \
 && cd /tmp/dante \
    # https://www.inet.no/dante/download.html
 && curl -L https://www.inet.no/dante/files/dante-1.4.2.tar.gz | tar xz --strip-components 1 \
    # See https://lists.alpinelinux.org/alpine-devel/3932.html
 && ./configure \
 && make install \
 && cd / \
    # Add an unprivileged user.
 && useradd --system --uid 8062 --no-create-home --shell /usr/sbin/nologin sockd \
    # Install dumb-init (avoid PID 1 issues).
    # https://github.com/Yelp/dumb-init
 && DUMP_INIT_URI=$(curl -L https://github.com/Yelp/dumb-init/releases/latest | grep -Po '(?<=href=")[^"]+_amd64(?=")') \
 && curl -Lo /usr/local/bin/dumb-init "https://github.com/$DUMP_INIT_URI" \
 && chmod +x /usr/local/bin/dumb-init \
    # Clean up.
 && rm -rf /tmp/* \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Default configuration
COPY sockd.conf /etc/

EXPOSE 1080

ENTRYPOINT ["dumb-init"]
CMD ["sockd"]
