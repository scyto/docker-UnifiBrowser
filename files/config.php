
<?php
/**
 * Copyright (c) 2023, Art of WiFi
 * www.artofwifi.net
 *
 * This file is subject to the MIT license that is bundled with this package in the file LICENSE.md
 */

/**
 * Configuration instructions
 * ===========================
 * Create a copy of this configuration template file within the same directory, name it config.php and enter your
 * UniFi controller details and credentials below
 *
 * Multi controller configuration options
 * =======================================
 * The number of UniFi controllers that can be added is unlimited, just take care to correctly maintain
 * the array structure by following PHP syntax shown below.
 *
 * **All fields are required for each controller**
 *
 * If a controller configuration is incomplete, an error will the thrown upon selection
 */
/**
 * Controller selection (one mode at a time)
 * =========================================
 * This image configures ONE controller from environment variables in EITHER:
 *   - Official UniFi Network Application API (API key auth) -- selected by
 *     setting APIKEY to a non-empty value.
 *   - Classic controller (username/password) -- the default, used whenever
 *     APIKEY is unset/empty. Existing deployments are unaffected.
 * The two modes are mutually exclusive: provide credentials for one or the other.
 */
if (getenv('APIKEY') !== false && getenv('APIKEY') !== '') {
    // Official UniFi Network Application API (type 'official', API key auth)
    $controllers = [
        [
            'type'       => 'official', // use the official API client
            'api_key'    => getenv('APIKEY'), // API key generated in the UniFi Network Application
            'url'        => getenv('UNIFIURL') . ":" . getenv('PORT'), // full url to the controller, eg. 'https://192.168.1.1:443'
            'name'       => getenv('DISPLAYNAME'), // name for this controller which will be used in the dropdown menu
            'verify_ssl' => filter_var(getenv('VERIFYSSL'), FILTER_VALIDATE_BOOLEAN), // VERIFYSSL=true enforces TLS verification; default false suits self-signed UDM/UDMP certs
        ],
    ];
} else {
    // Classic controller (username/password) -- default, backward compatible
    $controllers = [
        [
            'user'     => getenv('USER'), // the user name for access to the Unifi Controller
            'password' => getenv('PASSWORD'), // the password for access to the Unifi Controller
            'url'      => getenv('UNIFIURL') . ":" . getenv('PORT'), // full url to the Unifi Controller, eg. 'https://22.22.11.11:8443'
            'name'     => getenv('DISPLAYNAME'), // name for this controller which will be used in the dropdown menu
        ],
#        [
#            'user'     => 'demo2', // add more controllers by editing this file directly
#            'password' => 'demo2',
#            'url'      => 'https://demo.ui.com:443',
#            'name'     => 'demo2.ubnt.com'
#        ],
    ];
}

/**
 * Optionally change the default values for options below
 */
$theme           = 'bootstrap'; // your default theme of choice, pick one from the list below:
                                // bootstrap, cerulean, cosmo, cyborg, darkly, flatly, journal, lumen, paper
                                // readable, sandstone, simplex, slate, spacelab, superhero, united, yeti

$navbar_class    = 'dark';      // class for the main navigation bar, valid options are: light, dark
$navbar_bg_class = 'dark';      // class for the main navigation bar background, valid options are:
                                // primary, secondary, success, danger, warning, info, light, dark, white, transparent

$debug           = false;       // set to true (without quotes) to enable debug output to the browser and the PHP error log
                                // when fetching the sites collection after selecting a controller
