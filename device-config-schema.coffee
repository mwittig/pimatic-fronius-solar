module.exports = {
  title: "pimatic-websolarlog device config schemas"
  FroniusInverterRealtimeData: {
    title: "Fronius Realtime Data Device"
    description: "Provides access to real-time data of a Fronius Inverter supporting Solar API 1.1"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      deviceId:
        description: "The id of the Inverter Device"
        type: "number"
      host:
        description: "IP address or hostname of the device providing the Solar REST Service"
        type: "string"
      apiVersion:
        description: "The API Version supported by the data logger device"
        enum: [0, 1]
        default: 1
      port:
        description: "Port of the device providing the Solar REST Service"
        type: "number"
        default: 80
      username:
        description: "Username used to obtain access. Omitted, if authentication has been disabled."
        type: "string"
        required: false
      password:
        description: "Password used to obtain access. Omitted, if authentication has been disabled."
        type: "string"
        required: false
      interval:
        description: "Polling interval in seconds, value range [10-86400]"
        type: "number"
        default: 60
      threshold:
        description: "Threshold for PowerSaveMode of Inverter Device"
        type: "number"
        default: 0
  }
  FroniusComponentsData: {
    title: "Fronius GetComponentsData Device (using an undocumented API call of the PV data logger)"
    description: "Provides access to data of a Fronius Inverter supporting Solar API 1.1"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      attributes:
        type: "array"
        default: ["powerGenerate", "powerLoad", "powerGrid", "powerAkkuSum", "powerPvSum", "relativeSelfConsumption", "relativeAutonomy", "powerSelfConsumption"]
        format: "table"
        items:
          type: "string"
      host:
        description: "IP address or hostname of the device providing the Solar REST Service"
        type: "string"
      port:
        description: "Port of the device providing the Solar REST Service"
        type: "number"
        default: 80
      username:
        description: "Username used to obtain access. Omitted, if authentication has been disabled."
        type: "string"
        required: false
      password:
        description: "Password used to obtain access. Omitted, if authentication has been disabled."
        type: "string"
        required: false
      interval:
        description: "Polling interval in seconds, value range [10-86400]"
        type: "number"
        default: 60
      threshold:
        description: "Threshold for PowerSaveMode of Inverter Device"
        type: "number"
        default: 0
  }
  FroniusPowerFlowRealtimeData: {
    title: "Fronius GetPowerFlowRealtimeData Device "
    description: "Provides access to data of a Fronius Inverter supporting Solar API 1.1"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      attributes:
        type: "array"
        default: ["mode", "powerGrid", "powerLoad", "powerAkku", "powerGenerate", "energyDay", "energyYear", "energyTotal"]
        format: "table"
        items:
          type: "string"
      host:
        description: "IP address or hostname of the device providing the Solar REST Service"
        type: "string"
      port:
        description: "Port of the device providing the Solar REST Service"
        type: "number"
        default: 80
      username:
        description: "Username used to obtain access. Omitted, if authentication has been disabled."
        type: "string"
        required: false
      password:
        description: "Password used to obtain access. Omitted, if authentication has been disabled."
        type: "string"
        required: false
      interval:
        description: "Polling interval in seconds, value range [10-86400]"
        type: "number"
        default: 60
      threshold:
        description: "Threshold for PowerSaveMode of Inverter Device"
        type: "number"
        default: 0
  }
}