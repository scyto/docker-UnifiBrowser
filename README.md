# Unifi-API-Browser v2.0.26

 Docker for unifi browser <https://github.com/Art-of-WiFi/UniFi-API-browser>

Includes support for UniFiOS on UDMP - see note on ports

 The API Browser lets you pull raw, JSON formatted data from the API running on your controller.

## Controller authentication: classic or official API

This container talks to your controller in **one** of two mutually-exclusive modes:

- **Classic (username / password)** — the default. Set `USER` + `PASSWORD`. Unchanged from previous versions.
- **Official UniFi Network Application API (API key)** — set `APIKEY` to a key generated in your UniFi Network Application. When `APIKEY` is non-empty the container uses the official API and ignores `USER`/`PASSWORD`.

Either way you still set `UNIFIURL`, `PORT`, and `DISPLAYNAME`. Pick one mode — don't set both `APIKEY` and `USER`/`PASSWORD` expecting them to combine.

## Required Environment Variables
 To run this container you will need to define the following variables:

| Environment Variable | Default                     | Explanation                                                                                                                                    |
|----------------------|-----------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| USER                 | Your unifi username         | **Classic mode.** Your username on unifi console - consider creating a restricted user                                                          |
| PASSWORD             | Your unifi password         | **Classic mode.** clear text unifi password                                                                                                    |
| APIKEY               | _(empty)_                   | **Official API mode.** API key from the UniFi Network Application. Set this to use the official API instead of USER/PASSWORD; leave empty for classic mode |
| VERIFYSSL            | false                       | **Official API mode.** Set to `true` to enforce TLS certificate verification; default `false` works with the self-signed certs on UDM / UDMP   |
| UNIFIURL             | https://192.168.1.1         | URL to your controller *without* the port or trailing / on the URL                                                                                                      |
| PORT                 | 443                        | Port if you changed the port unifi is running on - default env var setting 443 is now the default for UDM / UDMP for older UniFiOS based controllers change to 8443 controllers                                                                                               |
| DISPLAYNAME          | My Site Name                | Arbitrary name you want to refer to this site as in API Browser                                                                                |
| NOAPIBROWSERAUTH     | 0                           | use to disable browser auth
| APIBROWSERUSER       | admin                       | username to secure the API Browser instance                                                                                                    |
| APIBROWSERPASS       | see note | Note: Generate a SHA512 of the password you want and put here, you can use a tool like https://abunchofutils.com/u/computing/sha512-hash-calculator/ as an example this is the password 'admin': c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd472634dfac71cd34ebc35d16ab7fb8a90c81f975113d6c7538dc69dd8de9077ec|

`APIBROWSERUSER` / `APIBROWSERPASS` / `NOAPIBROWSERAUTH` secure the API Browser tool itself and apply in both modes.

## Getting Running
To get started this is the minimum number of options, be sure to append each envar with the required text (esp the SHA512):

`docker run --name unifiapibrowser -p:8000:8000 -e USER= -e PASSWORD= -e UNIFIURL= -e APIBROWSERPASS=    ghcr.io/scyto/docker-unifibrowser`

This will run the container on host port 8000/tcp.

## Using Docker Compose / Stack

This is the fastest way to get running for unifios and doesn't require the use of the hash
```
services:
  unifiapibrowser:
    ports:
    - 8010:8000
    environment:
      USER: unifi console local account 
      PASSWORD: unifi console password
      NOAPIBROWSERAUTH: 1 # disables auth to apibrowser
      UNIFIURL: https://192.168.1.1
      PORT: 443
      DISPLAYNAME: Home
    image: ghcr.io/scyto/docker-unifibrowser
 ```   

### Official API (API key) instead of username / password

Set `APIKEY` (and omit `USER`/`PASSWORD`) to use the official UniFi Network Application API:
```
services:
  unifiapibrowser:
    ports:
    - 8010:8000
    environment:
      APIKEY: your-unifi-network-application-api-key
      VERIFYSSL: "false"   # set true only if your controller has a trusted cert
      NOAPIBROWSERAUTH: 1
      UNIFIURL: https://192.168.1.1
      PORT: 443
      DISPLAYNAME: Home
    image: ghcr.io/scyto/docker-unifibrowser
```

## Using Multiple Unifi Controllers

Unifi-API-Browser supports multiple controllers.  To use them copy the users.php and config.php into a host directory and the map them into the container with the additional following command line options:

`-v <YourHostPath>/config.php:/UniFi-API-browser/config/config.php` 

and

`-v <YourHostPath>/config.php:/UniFi-API-browser/config/users.php`

Editing these files is beyond the scope of this readme.md but both contain good instructions

### Feedback
If you find any issues please log them at the github repo https://github.com/scyto/docker-UnifiBrowser
