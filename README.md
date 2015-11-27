# pimatic-fronius-solar

[![npm version](https://badge.fury.io/js/pimatic-fronius-solar.svg)](http://badge.fury.io/js/pimatic-fronius-solar)

Pimatic Plugin to access PV live logs using the Fronius Solar API - <http://www.fronius.com>.

Note, this is an early version of the plugin provided for testing purposes. Please provide feedback via 
[github](https://github.com/mwittig/node-fronius-solar/issues).

## Configuration

You can load the plugin by editing your `config.json` to include the following in the `plugins` section. The property 
`interval` specifies the time interval in seconds for updating the data set. For debugging purposes you may set 
property `debug` to true. This will write additional debug messages to the pimatic log. The values
properties `interval` and `debug` represent the the default values. 

    {
          "plugin": "fronius-solar",
          "interval": 60,
          "debug": false
    },

Then you need to add a device in the `devices` section. Currently, only the following device type is supported:

* FroniusInverterRealtimeData: This type is to obtain the realtime measurements data for an inverter device
  
As part of the device definition you need to provide the `deviceId` which is the number of the inverter devices 
according to your PV system setup. You also need to provide host and port of the device proving Solar API, which is 
either your inverter (Fronius Galvo and Fronius Symo inverter models) or a  Fronius Datamanager.

If you've configured your Fronius inverter to use power save mode, enter the threshold in watts at which power saving is activated. This helps to omit the nightly errors of the unreachable server.

    {
          "id": "fronius1",
          "class": "FroniusInverterRealtimeData",
          "name": "Fronius Inverter",
          "host": "fronius.fritz.box",
          "port": 8001,
          "deviceId": 1
          "threshold": 50
    }

## Contributions and Donations

[![PayPal donate button](https://img.shields.io/paypal/donate.png?color=blue)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=E44SSB34CVXP2)

Contributions to the project are welcome. You can simply fork the project and create a pull request with your contribution to start with. If you wish to support my work with a donation I'll highly appreciate this. 

## History

* 20150514, V0.0.1
    * Initial Version
* 20150518, V0.0.2
    * Improved error handling
* 20150520, V0.0.3
    * Attribute values are now recovered from DB (lastState) on pimatic startup rather than using zero values
* 20150520, V0.0.4
    * Added status attribute representing the status of the inverter device
    * Fixed bug "TypeError: Cannot call method 'hasOwnProperty' of undefined"
    * PAC, IAC, UAC are now transient values (not recovered from DB on startup)
* 20150526, V0.0.5
    * Nullify IAC, UAC & PAC if no value has been received (inverter shutting down) or an error has occurred
* 20150623, V0.0.6
    * Revised license information to provide a SPDX 2.0 license identifier in-line with npm v2.1 guidelines on license
      metadata - see also https://github.com/npm/npm/releases/tag/v2.10.0
* 20151127, V0.0.7
    * Added parameter "threshold" to support the powersave mode of the inverter and to omit errors during 
      powersave (contributed by @mplessing)