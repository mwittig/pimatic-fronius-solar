# #FroniusSolar plugin

module.exports = (env) ->

# Require the bluebird promise library
  Promise = env.require 'bluebird'

  # Require the lodash library
  _ = env.require 'lodash'

  # Require the nodejs net API
  net = require 'net'

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
          @emit "realtimeData", values
        else
          newError = "Invalid Status, status code=" + status.Code + ', ' + status.Reason || "reason unknown"
          env.logger.error newError if newError isnt @_lastError or @debug
          @_lastError = newError
      ).catch((error) =>
        newError = "Unable to get inverter realtime data from device id=" + id + ": " + error.toString()
        env.logger.error newError if newError isnt @_lastError or @debug
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
        if not _.isObject obj or not obj.hasOwnProperty key
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

    energyToday: 0.0
    energyYear: 0.0
    energyTotal: 0.0
    currentPower: 0.0
    currentAmperage: 0.0
    currentVoltage: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      env.logger.debug("FroniusSolarProductionDevice Initialization") if @debug
      @energyToday = lastState?.energyToday?.value or 0.0
      @energyYear = lastState?.energyYear?.value or 0.0
      @energyTotal = lastState?.energyTotal?.value or 0.0
      @currentPower = lastState?.currentPower?.value or 0.0
      @currentAmperage = lastState?.currentAmperage?.value or 0.0
      @currentVoltage = lastState?.currentVoltage?.value or 0.0

      @on 'realtimeData', ((values) ->
        data = values.Body.Data
        @_setAttribute 'energyToday', Number data.DAY_ENERGY.Value  if @_has data, "DAY_ENERGY.Value"
        @_setAttribute 'energyYear', Number data.YEAR_ENERGY.Value  if @_has data, "YEAR_ENERGY.Value"
        @_setAttribute 'energyTotal', Number data.TOTAL_ENERGY.Value  if @_has data, "TOTAL_ENERGY.Value"
        @_setAttribute 'currentPower', Number data.PAC.Value  if @_has data, "PAC.Value"
        @_setAttribute 'currentAmperage', Number data.IAC.Value  if @_has data, "IAC.Value"
        @_setAttribute 'currentVoltage', Number data.UAC.Value  if @_has data, "UAC.Value"
      )
      super(@config, @plugin)

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