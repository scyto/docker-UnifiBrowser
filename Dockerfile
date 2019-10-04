# Use alpine base image
FROM alpine

# Copy the current directory contents into the container at /
COPY start.sh .

# Install any needed packages

RUN apk update \
  && apk add --no-cache php php-session php-curl composer git \
  && git clone --depth 1 https://github.com/Art-of-WiFi/UniFi-API-browser.git \
  && chmod +x start.sh \
  && cd UniFi-API-browser \
  && composer install \
  && apk del git composer

# Define environment variable
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG C.UTF-8

# Run  when the container launches
ENTRYPOINT ["./start.sh"]

EXPOSE 8000/tcp
