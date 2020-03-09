# Unifi-API-Browser v2

 Docker for unifi browser <https://github.com/Art-of-WiFi/UniFi-API-browser>

Includes support for UniFiOS on UDMP - see note on ports

 The API Browser lets you pull raw, JSON formatted data from the API running on your controller.

## Required Environment Variables
 To run this container you will need to define the following variables:

| Environment Variable | Default                     | Explanation                                                                                                                                    |
|----------------------|-----------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| USER                 | Your unifi username         | Your username on unifi console - consider creating a restricted user                                                                           |
| PASSWORD             | Your unifi password         | clear text unifi password                                                                                                                      |
| UNIFIURL             | https://192.168.1.1         | URL to your controller *without* the port                                                                                                      |
| PORT                 | 8443                        | Port if you changed the port unifi is running on 8443 (default env var setting) for older controllers, 443 for UniFiOS based controllers                                                                                               |
| DISPLAYNAME          | My Site Name                | Arbitrary name you want to refer to this site as in API Browser                                                                                |
| APIBROWSERUSER       | admin                       | username to secure the API Browser instance                                                                                                    |
| APIBROWSERPASS       | SHA512 hash of the password | Generate a SHA512 of the password you want and put here, you can use a tool like https://abunchofutils.com/u/computing/sha512-hash-calculator/ |

## Getting Running
To get started this is the minimum number of options, be sure to append each envar with the required text (esp the SHA512):

`docker run --name unifiapibrowser -p:8000:8000 -e USER= -e PASSWORD= -e UNIFIURL= -e APIBROWSERPASS=    scyto/unifibrowser`

This will run the container on host port 8000/tcp.

## Using Multiple Unifi Controllers

Unifi-API-Browser supports multiple controllers.  To use them copy the users.php and config.php into a host directory and the map them into the container with the additional following command line options:

`-v <YourHostPath>/config.php:/UniFi-API-browser/config/config.php` 

and

`-v <YourHostPath>/config.php:/UniFi-API-browser/config/users.php`

Editing these files is beyond the scope of this readme.md but both contain good instructions

### Feedback
If you find any issues please login them at the github repo https://github.com/scyto/docker-UnifiBrowser
