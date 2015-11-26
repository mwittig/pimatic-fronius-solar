# #FroniusSolar plugin

module.exports = (env) ->

# Require the bluebird promise library
  Promise = env.require 'bluebird'

  # Require the lodash library
  _ = env.require 'lodash'

  # Require the nodejs net API
  net = require 'net'
  i18n = env.require 'i18n'

  fronius = require 'node-fronius-solar'

  # ###FroniusSolarPlugin class
  class FroniusSolarPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      # register devices
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("FroniusInverterRealtimeData", {
        configDef: deviceConfigDef.FroniusInverterRealtimeData,
        createCallback: (config, lastState) =>
          return new FroniusInverterRealtimeDataDevice config, @, lastState
      })

  class FroniusBaseDevice extends env.devices.Device
    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin) ->
      @debug = plugin.config.debug;
      env.logger.debug("FroniusSolarBaseDevice Initialization") if @debug
      @id = config.id
      @name = config.name
      @interval = 1000 * @_normalize config.interval, 10, 86400
      @threshold = config.threshold
      @options = {
        deviceId: config.deviceId,
        host: config.host,
        port: config.port,
        timeout: Math.min @interval, 20000
      }
      @_lastError = ""
      super()
      @_scheduleUpdate()


# poll device according to interval
    _scheduleUpdate: () ->
      unless typeof @intervalObject is 'undefined'
        clearInterval(@intervalObject)

      # keep updating
      if @interval > 0
        @intervalObject = setInterval(=>
          @_requestUpdate()
        , @interval
        )

      # perform an update now
      @_requestUpdate()

    _requestUpdate: ->
      id = @id
      fronius.GetInverterRealtimeData(@options).then((values) =>
        #console.log values
        status = values.Head.Status
        if status.Code is 0
          @_lastError = ""
          @emit "realtimeData", null, values
        else
          newError = "Invalid Status, status code=" + status.Code + ', ' + status.Reason || "reason unknown"
          @emit "realtimeData", newError if newError isnt @_lastError
          @_lastError = newError
      ).catch((error) =>
        newError = "Unable to get inverter realtime data from device id=" + id + ": " + error.toString()
        @emit "realtimeData", newError if newError isnt @_lastError
        @_lastError = newError
      )

    _normalize: (value, lowerRange, upperRange) ->
      if upperRange
        return Math.min (Math.max value, lowerRange), upperRange
      else
        return Math.max value lowerRange

    _has: (obj, path) ->
      return false if not _.isObject obj or not _.isString path
      keys = path.split '.'
      for key in keys
        if not _.isObject(obj) or not obj.hasOwnProperty(key)
          return false
        obj = obj[key]
      return true

    _setAttribute: (attributeName, value) ->
      if @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value


  class FroniusInverterRealtimeDataDevice extends FroniusBaseDevice
    # attributes
    attributes:
      status:
        description: "Device Status"
        type: "string"
        acronym: 'STATUS'
      energyToday:
        description: "Energy Yield Today"
        type: "number"
        unit: 'Wh'
        acronym: 'KDY'
      energyYear:
        description: "Energy Yield of Current Year"
        type: "number"
        unit: 'Wh'
        acronym: 'KYR'
      energyTotal:
        description: "Energy Yield Total"
        type: "number"
        unit: 'Wh'
        acronym: 'KT0'
      currentPower:
        description: "AC Power"
        type: "number"
        unit: 'W'
        acronym: 'PAC'
      currentAmperage:
        description: "AC Current"
        type: "number"
        unit: 'A'
        acronym: 'IAC'
      currentVoltage:
        description: "AC Voltage"
        type: "number"
        unit: 'V'
        acronym: 'UAC'

    status: "Unknown"
    energyToday: 0.0
    energyYear: 0.0
    energyTotal: 0.0
    currentPower: 0.0
    currentAmperage: 0.0
    currentVoltage: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      env.logger.debug("FroniusSolarProductionDevice Initialization") if @debug
      @status = "Unknown"
      @energyToday = lastState?.energyToday?.value or 0.0
      @energyYear = lastState?.energyYear?.value or 0.0
      @energyTotal = lastState?.energyTotal?.value or 0.0
      @currentPower = 0.0
      @currentAmperage = 0.0
      @currentVoltage = 0.0

      @on 'realtimeData', ((error, values) ->
        if error or not values
          if error and @currentPower > @threshold
            @_setAttribute 'status', i18n.__("Error")
            env.logger.error error
          else
            env.logger.debug error if @debug
            @_setAttribute 'status', i18n.__("Unknown")          
          @_setAttribute 'currentPower', 0.0
          @_setAttribute 'currentAmperage', 0.0
          @_setAttribute 'currentVoltage', 0.0
        else
          data = values.Body.Data
          newStatus = "Unknown"
          if @_has(data, "DeviceStatus.StatusCode") and _.isNumber(data.DeviceStatus.StatusCode)
            switch data.DeviceStatus.StatusCode
              when 7 then  newStatus = "Running"
              when 8 then  newStatus = "Standby"
              when 9 then  newStatus = "Boot Loading"
              when 10 then  newStatus = "Error"
              else newStatus = "Startup"

          @_setAttribute 'status', i18n.__(newStatus)
          @_setAttribute 'energyToday', Number data.DAY_ENERGY.Value  if @_has data, "DAY_ENERGY.Value"
          @_setAttribute 'energyYear', Number data.YEAR_ENERGY.Value  if @_has data, "YEAR_ENERGY.Value"
          @_setAttribute 'energyTotal', Number data.TOTAL_ENERGY.Value  if @_has data, "TOTAL_ENERGY.Value"
          @_setAttribute 'currentPower', if @_has data, "PAC.Value" then Number data.PAC.Value else 0.0
          @_setAttribute 'currentAmperage', if @_has data, "IAC.Value" then Number data.IAC.Value else 0.0
          @_setAttribute 'currentVoltage', if @_has data, "UAC.Value" then Number data.UAC.Value else 0.0
      )
      super(@config, @plugin)

    getStatus: -> Promise.resolve @status
    getEnergyToday: -> Promise.resolve @energyToday
    getEnergyYear: -> Promise.resolve @energyYear
    getEnergyTotal: -> Promise.resolve @energyTotal
    getCurrentPower: -> Promise.resolve @currentPower
    getCurrentAmperage: -> Promise.resolve @currentAmperage
    getCurrentVoltage: -> Promise.resolve @currentVoltage

  # ###Finally
  # Create a instance of my plugin
  myPlugin = new FroniusSolarPlugin
  # and return it to the framework.
  return myPlugin