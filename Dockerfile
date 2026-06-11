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

# Keep the app at /UniFi-API-browser (not under a WORKDIR), so the config dir
# stays at /UniFi-API-browser/config -- the bind-mount path the README documents
# for multi-controller setups. Moving it would silently ignore users' mounts.
WORKDIR /

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
# Official UniFi Network Application API (API key auth). Leave APIKEY empty to use
# the classic USER/PASSWORD controller above; set APIKEY to switch to the official
# API. VERIFYSSL=true enforces TLS verification (default false for self-signed
# UDM/UDMP certs).
ENV APIKEY=""
ENV VERIFYSSL="false"
ENV APIBROWSERUSER="admin"

# this sets password for APIBROWSERUSER to admin - please change when you do this
ENV APIBROWSERPASS=""

# Run when the container launches
CMD ["sh", "./start.sh"]
EXPOSE 8000/tcp
