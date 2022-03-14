# Use alpine base image
FROM alpine:3.14

# Copy the current directory contents into the container at /
COPY /files .

# Install any needed packages

RUN apk update \
  && apk add --no-cache php php-session php-curl php-tokenizer composer git \
  && git clone --depth 1 https://github.com/Art-of-Wifi/UniFi-API-browser.git \
  && apk del git \
  && chmod +x start.sh \
  && cd UniFi-API-browser \
  && cd .. \
  && mv config.php /UniFi-API-browser/config \
  && mv users.php /UniFi-API-browser/config

# Define environment variable
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG C.UTF-8
ENV TZ America/Los_Angeles
ENV USER your unifi username
ENV PASSWORD your unifi password
ENV UNIFIURL https://192.168.1.1
ENV PORT 443
ENV NOAPIBROWSERAUTH 0
ENV DISPLAYNAME My Site Name
ENV APIBROWSERUSER admin

# this sets password for APIBROWSERUSER to admin - please change when you do this
ENV APIBROWSERPASS c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd472634dfac71cd34ebc35d16ab7fb8a90c81f975113d6c7538dc69dd8de9077ec


# Run  when the container launches
# ENTRYPOINT ["./start.sh"]
# ENTRYPOINT ["./bin/ash"]
CMD ["sh", "./start.sh"]
EXPOSE 8000/tcp
