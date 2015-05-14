# pimatic-websolarlog

[![npm version](https://badge.fury.io/js/pimatic-websolarlog.svg)](http://badge.fury.io/js/pimatic-websolarlog)

Pimatic Plugin for WebSolarLog (WSL), an open-source data logger for PV systems - <http://www.websolarlog.com>.

Note, this is an early version of the plugin provided for testing purposes. Please provide feedback via 
[github](https://github.com/mwittig/node-websolarlog/issues) or 
[pimatic-forum](http://forum.pimatic.org/category/13/plugins).

## Configuration

You can load the plugin by editing your `config.json` to include the following in the `plugins` section. The property 
`interval` specifies the time interval in seconds for updating the data set. For debugging purposes you may set 
property `debug` to true. This will write additional debug messages to the pimatic log. The values
properties `interval` and `debug` represent the the default values. 

    {
          "plugin": "websolarlog",
          "interval": 30,
          "debug": false
    },

Then you need to add a device in the `devices` section. Currently, only the following device type is supported:

* WebSolarProduction: This type is for solar power production devices. It provides attributes for the current 
  power produced,
  
As part of the device definition you need to provide the `deviceName` which is the name of the Production Device 
as it has been set via WebSolarLog Admin. You also need to provide the `url` for the Live page of your WebSolarLog
server.

    {
          "id": "wsl1",
          "class": "WebSolarLogProduction",
          "name": "WSL Test",
          "deviceName": "Diehl",
          "url": "http://diehl-inverter-demo.websolarlog.com/api.php/Live",
    }

## Contributions and Donations

[![PayPal donate button](https://img.shields.io/paypal/donate.png?color=blue)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=E44SSB34CVXP2)

Contributions to the project are welcome. You can simply fork the project and create a pull request with your contribution to start with. If you wish to support my work with a donation I'll highly appreciate this. 

## History

* 20150417, V0.0.1
    * Initial Version
