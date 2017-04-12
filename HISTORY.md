# Release History

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
* 20160311, V0.0.8      
    * Fixed _normalize() function missing comma
    * Updated to node-fronius-solar@0.0.4
* 20160322, V0.0.9
    * Fixed compatibility issue with Coffeescript 1.9 as required for pimatic 0.9 (thanks @sweebee)
    * Updated peerDependencies property for compatibility with pimatic 0.9
* 20160325, V0.0.10
    * Added default value 80 for port property in device config schema
    * Updated README configuration example
    * Added license info to README
    * Updated list of contributors
    * Moved release history to separate file
* 20160331, V0.0.11
    * Implemented new devices FroniusComponentsData and FroniusPowerFlowRealtimeData 
      based on extension node-fronius-solar@0.0.6
    * Refactoring, now using pimatic-plugin-commons
    * Updated README
* 20160417, V0.0.12
    * Added destroy method to cancel an scheduled update when the device is removed or updated
* 20160601, V0.0.13
    * Added support for Fronius API V0 callouts to GetInverterRealtimeData 
* 20160831, V0.0.14 
    * Dependency Update
    * Handle updates of FroniusComponentsData and FroniusPowerFlowRealtimeData device attributes 
      as continuous values
* 20160901, V0.0.15
    * Fixed creation of getter methods for dynamic attributes of FroniusComponentsData and FroniusPowerFlowRealtimeData 
      which wrong accessor for attribute values, issue #3
* 20160901, V0.0.16
    * Fixed updating attribute values for FroniusInverterRealtimeDataDevice, issue #3
* 20170412, V0.0.17
    * Updated dependencies
    * Revised README, updated copyright notice