FROM registry.gitlab.com/jitesoft/dockerfiles/alpine:latest
LABEL maintainer="Johannes Tegnér <johannes@jitesoft.com>"

ARG KEYS="6FE198C8"

ENV PORT=80 \
    SERVER_NAME="localhost" \
    SERVER_ROOT="/var/www/html/" \
    CONFIG_FILE="/etc/lighttpd/lighttpd.conf"

ADD startup.sh /startup
RUN addgroup -g 1000 -S lighttpd && adduser -u 1000 -S lighttpd -G lighttpd \
    && apk add --no-cache --virtual .trash curl grep gnupg \
    && VERSION=$(curl -s https://download.lighttpd.net/lighttpd/releases-1.4.x/ | tac | tac | grep -oPm1 "(?<=lighttpd-)(1.4.[0-9]+)" | tail -n 1) \
    && curl -OsS https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-${VERSION}.tar.xz \
            -OsS https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-${VERSION}.tar.xz.asc \
            -OsS https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-${VERSION}.sha256sum \
    && for key in ${KEYS}; do \
        gpg --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys "$key" 2>&1 || \
        gpg --keyserver hkp://keyserver.pgp.com:80 --recv-keys "$key" 2>&1 || \
        gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key"; \
    done \
    && gpg --verify lighttpd-${VERSION}.tar.xz.asc lighttpd-${VERSION}.tar.xz \
    && grep " lighttpd-${VERSION}.tar.xz\$" lighttpd-${VERSION}.sha256sum | sha256sum -c - \
    && tar -xf lighttpd-${VERSION}.tar.xz \
    && rm lighttpd-${VERSION}.tar.xz.asc lighttpd-${VERSION}.sha256sum lighttpd-${VERSION}.tar.xz \
    && apk del .trash \
    && apk add --no-cache --virtual .build-deps build-base flex automake autoconf libressl-dev zlib-dev bzip2-dev lua5.3-dev openldap-dev libxml2-dev sqlite-dev libev-dev gamin-dev \
    && apk add --no-cache --virtual .req pcre-dev \
    && ./lighttpd-${VERSION}/configure --with-lua --with-openssl --with-ldap \
    && make lighttpd-${VERSION} \
    && make install lighttpd-${VERSION} \
    && rm -rf lighttpd-${VERSION} \
    && apk del .build-deps \
    && chmod +x /startup

ADD --chown=lighttpd:lighttpd lighttpd.conf /etc/lighttpd/lighttpd.conf

CMD /startup
