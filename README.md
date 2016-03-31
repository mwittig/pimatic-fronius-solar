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

Then you need to add a device in the `devices` section. Currently, the following device types are supported:

* `FroniusInverterRealtimeData`: This type is to obtain the measurements data for an inverter device using the 
  `GetInverterRealtimeData` service call of the Solar API V0/V1
* `FroniusComponentsData`: This type is to obtain the measurements data for an PV system using an undocumented API 
  service provided by the Fronius Data Manager provided with Symo inverters. In contrast to the regular 
  Solar API Calls which do not require authentication, you may need to provide username and password properties 
  to the options dictionary (if authentication has been enabled
* `FroniusPowerFlowRealtimeData`: This type is to obtain the measurements data for an PV system using the 
  `GetInverterRealtimeData` service call of the Solar API V1 which should work with Fronius Data 
  Manager v3.4.2-1 (and higher)
  
As part of the `FroniusInverterRealtimeData` device definition you need to provide the `deviceId` which is the number 
of the inverter devices according to your PV system setup. You also need to provide host of the device providing 
Solar API, which is either your inverter (Fronius Galvo and Fronius Symo inverter models) or a Fronius Datamanager 
device. 

For `FroniusComponentsData` and `FroniusPowerFlowRealtimeData` device configuration you can choose which 
attributes should be exposed by the device. See 
[device-config-schema](https://github.com/mwittig/pimatic-fronius-solar/blob/master/device-config-schema.coffee) 
for details. 

If you've configured your Fronius inverter to use power save mode, enter the threshold in watts at which power 
saving is activated. This helps to omit the nightly errors of the unreachable server.

    {
          "id": "fronius1",
          "class": "FroniusInverterRealtimeData",
          "name": "Fronius Inverter",
          "host": "fronius.fritz.box",
          "deviceId": 1
          "threshold": 50
    },
    {
          "id": "fronius2",
          "class": "FroniusComponentsData",
          "name": "Fronius Inverter 2",
          "host": "fronius.fritz.box",
          "username": "admin",
          "password": "admin",
          "attributes": [
            "powerGenerate", 
            "powerLoad", 
            "powerGrid", 
            "powerAkkuSum", 
            "powerPvSum", 
            "relativeSelfConsumption", 
            "relativeAutonomy", 
            "powerSelfConsumption"
          ]
        },
        {
          "id": "fronius3",
          "class": "FroniusPowerFlowRealtimeData",
          "name": "Fronius Inverter 3",
          "host": "fronius.fritz.box",
          "attributes": [
            "mode",
            "powerGrid",
            "powerLoad",
            "powerAkku",
            "powerGenerate",
            "energyDay",
            "energyYear",
            "energyTotal"
          ]
        },

## Contributions and Donations

[![PayPal donate button](https://img.shields.io/paypal/donate.png?color=blue)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=E44SSB34CVXP2)

Contributions to the project are welcome. You can simply fork the project and create a pull request with your contribution to start with. If you wish to support my work with a donation I'll highly appreciate this. 


## Release History

See [Release History](https://github.com/mwittig/pimatic-fronius-solar/blob/master/HISTORY.md).

## License

Copyright (c) 2016, Marcus Wittig and contributors. All rights reserved.

[AGPL-3.0 License](https://github.com/mwittig/pimatic-fronius-solar/blob/master/LICENSE).