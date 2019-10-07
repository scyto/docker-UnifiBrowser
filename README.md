# UnifiBrowser

 Docker for unifi browser <https://github.com/Art-of-WiFi/UniFi-API-browser>

 The API Browser lets you pull raw, JSON formatted data from the API running on your controller.

 This docker container is a minimal install and can be run using the following commands:

`docker run --name unifiapibrowser -P scyto/unifibrowser`
this will map the internal 8000 port to a random high TCP port, use docker container ls once the container is running to discover the host port.

`docker run --name unifiapibrowser -p 8000:8000 scyto/unifibrowser`
this will run the container on host port 8000/tcp.

If you find any issues please login them at the github repo

ToDo

* figure out multi-arch builds
* allow defintion of the port using an ENV VAR
