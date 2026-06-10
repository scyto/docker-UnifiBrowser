# PHP major.minor is the contract with upstream. check-releases.yml raises it
# only to satisfy UniFi-API-browser's composer.json `require.php` floor -- a
# plain Alpine or PHP patch release never bumps it, so it never triggers a
# rebuild. Using the official php image (not Alpine's phpNN packages) means any
# version the floor demands is guaranteed to exist as a tag.
ARG PHP_VERSION=8.3

# The official PHP CLI image already bundles every extension this app needs
# (curl, ctype, mbstring, openssl, session, tokenizer, json), so there is no
# docker-php-ext-install step. -alpine keeps the image small.
FROM php:${PHP_VERSION}-cli-alpine

# Upstream UniFi-API-browser version to install.
# Bump via .github/tracked-versions.json (check-releases.yml does this
# automatically). See https://github.com/Art-of-WiFi/UniFi-API-browser/releases
ARG UNIFI_BROWSER_VERSION=v3.0.0

WORKDIR /app

# start.sh, config.php and users.php
COPY files/ ./

# Upstream ships a committed vendor/ dir, so no composer install is needed.
# git is only used for the shallow clone and removed in the same layer.
RUN apk add --no-cache git \
  && git clone --depth 1 --branch "${UNIFI_BROWSER_VERSION}" https://github.com/Art-of-Wifi/UniFi-API-browser.git \
  && apk del git \
  && chmod +x start.sh \
  && mv config.php UniFi-API-browser/config \
  && mv users.php UniFi-API-browser/config

# Define environment variables
ENV LANG="C.UTF-8"
ENV TZ="America/Los_Angeles"
ENV USER="your unifi username"
ENV PASSWORD="your unifi password"
ENV UNIFIURL="https://192.168.1.1"
ENV PORT="443"
ENV NOAPIBROWSERAUTH="0"
ENV DISPLAYNAME="My Site Name"
ENV APIBROWSERUSER="admin"

# this sets password for APIBROWSERUSER to admin - please change when you do this
ENV APIBROWSERPASS="c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd472634dfac71cd34ebc35d16ab7fb8a90c81f975113d6c7538dc69dd8de9077ec"

# Run when the container launches
CMD ["sh", "./start.sh"]
EXPOSE 8000/tcp
