# Use alpine base image
FROM alpine

# Copy the current directory contents into the container at /
COPY /files .

# Install any needed packages

RUN apk update \
  && apk add --no-cache php php-session php-curl php-tokenizer composer git \
  && git clone --depth 1 https://github.com/Art-of-WiFi/UniFi-API-browser.git \
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
ENV PORT 8443
ENV DISPLAYNAME My Site Name
ENV APIBROWSERUSER admin
ENV APIBROWSERPASS SHA512 hash of the password

# Run  when the container launches
# ENTRYPOINT ["./start.sh"]
# ENTRYPOINT ["./bin/ash"]
CMD ["sh", "./start.sh"]
EXPOSE 8000/tcp