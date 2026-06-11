# Unifi-API-Browser v3.0.0

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

The environment variables configure a **single** controller. To use more than one you edit `config.php` by hand and mount your edited copy into the container.

**1. Get a copy of the shipped `config.php` to start from:**
```
docker cp unifiapibrowser:/UniFi-API-browser/config/config.php ./config.php
```

**2. In your copy, replace the whole `if (...) { ... } else { ... }` controller block with a plain list** — one block per controller. Example with two controllers, one of each type:
```php
$controllers = [
    [                                   // --- controller 1: API key ---
        'type'       => 'official',
        'api_key'    => 'PASTE-FIRST-API-KEY-HERE',
        'url'        => 'https://192.168.1.1:443',
        'name'       => 'Home',
        'verify_ssl' => false,
    ],                                  // <-- comma after every ] block
    [                                   // --- controller 2: user/password ---
        'user'     => 'local-admin',
        'password' => 'PASSWORD-HERE',
        'url'      => 'https://192.168.1.2:443',
        'name'     => 'Office',
    ],
];
```
The brackets that trip people up: the whole list is wrapped in `$controllers = [ ... ];`, each controller is one `[ ... ],` block inside it, and **every block ends with a comma** (`],`). Only change the text inside the `'quotes'`.

**3. Mount your edited file back over the container's copy:**
```
-v <YourHostPath>/config.php:/UniFi-API-browser/config/config.php
```
When you mount your own `config.php`, the controller environment variables (`USER`/`PASSWORD`/`APIKEY`/`UNIFIURL`/…) are ignored — your file is the full controller configuration. (Optionally mount a hand-edited `users.php` the same way to `/UniFi-API-browser/config/users.php` if you want to manage the API Browser login accounts directly instead of via `APIBROWSERUSER`/`APIBROWSERPASS`.)

## Troubleshooting

### Login fails with HTTP 403 / "UniFi controller login failure, please check the URL and credentials"

In **classic** (username / password) mode this means the controller rejected the login — it is not a container problem. Check, in order:

- **Double-check the username and password.** A wrong username throws this exact 403.
- Use a **local** UniFi admin account, **not** your Ubiquiti cloud / SSO (email) login — the private login API cannot complete a cloud sign-in.
- The account must **not** have MFA / 2FA. Local-only accounts don't by default; create one under **Settings → Admins** with **"Restrict to Local Access Only"** ticked and Full Management for UniFi Network.
- `UNIFIURL` is the controller address with **no trailing slash**; `PORT=443` on a UDM / UDMP / Cloud Gateway (`8443` is only for a legacy self-hosted controller).

(Confirmed working with a local account on UniFi OS 10.x.)

If you'd rather not manage a local account, switch to **API-key mode** — see the *Official API (API key)* section above. In that mode set `VERIFYSSL=false` for a controller using the default self-signed certificate.

### Feedback
If you find any issues please log them at the github repo https://github.com/scyto/docker-UnifiBrowser
