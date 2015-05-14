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
      port:
        description: "Port of the device providing the Solar REST Service"
        type: "number"
      interval:
        description: "Polling interval in seconds, value range [10-86400]"
        type: "number"
        default: 60
  }
}