# #FroniusSolar plugin

module.exports = (env) ->

# Require the bluebird promise library
  Promise = env.require 'bluebird'

  # Require the lodash library
  _ = env.require 'lodash'

  # Require the nodejs net API
  net = require 'net'
  i18n = env.require 'i18n'
  events = require 'events'

  fronius = require 'node-fronius-solar'
  commons = require('pimatic-plugin-commons')(env)

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
      @framework.deviceManager.registerDeviceClass("FroniusComponentsData", {
        configDef: deviceConfigDef.FroniusComponentsData,
        createCallback: (config, lastState) =>
          return new FroniusComponentsDataDevice config, @, lastState
      })
      @framework.deviceManager.registerDeviceClass("FroniusPowerFlowRealtimeData", {
        configDef: deviceConfigDef.FroniusPowerFlowRealtimeData,
        createCallback: (config, lastState) =>
          return new FroniusPowerFlowRealtimeDataDevice config, @, lastState
      })

  class FroniusBaseDevice extends env.devices.Device
    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, @service) ->
      @debug = @plugin.config.debug ? false
      @base = commons.base @, @config.class unless @base?

      @base.debug("Device Initialization")
      @id = @config.id
      @name = @config.name
      @interval = 1000 * @base.normalize @config.interval, 10, 86400
      @threshold = @config.threshold
      @options = {
        deviceId: @config.deviceId
        version: @config.apiVersion
        host: @config.host
        port: @config.port
        username: @config.username if @config.username?
        password: @config.password if @config.username?
        timeout: Math.min @interval, 20000
      }
      @_lastError = ""
      super()
      process.nextTick () =>
        @_requestUpdate()

    destroy: () ->
      @base.cancelUpdate()
      super()

    _requestUpdate: ->
      id = @id
      fronius[@service](@options).then((values) =>
        #console.log values
        status = values.Head.Status
        if status.Code is 0
          @_lastError = ""
          @emit "data", null, values
        else
          newError = "Invalid Status, status code=" + status.Code + ', ' + status.Reason || "reason unknown"
          @emit "data", newError if newError isnt @_lastError
          @_lastError = newError
      ).catch((error) =>
        newError = "Unable to get inverter data: " + error.toString()
        @emit "data", newError if newError isnt @_lastError
        @_lastError = newError
      ).finally(() =>
        @base.scheduleUpdate @_requestUpdate, @interval
      )

    _has: (obj, path) ->
      return false if not _.isObject obj or not _.isString path
      keys = path.split '.'
      for key in keys
        if not _.isObject(obj) or not obj.hasOwnProperty(key)
          return false
        obj = obj[key]
      return true


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
      @debug = @plugin.config.debug ? false
      @base = commons.base @, @config.class unless @base?
      @status = "Unknown"
      @energyToday = lastState?.energyToday?.value or 0.0
      @energyYear = lastState?.energyYear?.value or 0.0
      @energyTotal = lastState?.energyTotal?.value or 0.0
      @currentPower = 0.0
      @currentAmperage = 0.0
      @currentVoltage = 0.0

      @on 'data', ((error, values) ->
        if error or not values
          if error and @currentPower >= @threshold
            @base.setAttribute 'status', i18n.__("Error")
            @base.error error
          else
            @base.debug error
            @base.setAttribute 'status', i18n.__("Unknown")
          @base.setAttribute 'currentPower', 0.0
          @base.setAttribute 'currentAmperage', 0.0
          @base.setAttribute 'currentVoltage', 0.0
        else
          data = values.Body.Data
          newStatus = "Unknown"
          if @_has(data, "DeviceStatus.StatusCode") and _.isNumber(data.DeviceStatus.StatusCode)
            switch data.DeviceStatus.StatusCode
              when 7 then  newStatus = i18n.__("Running")
              when 8 then  newStatus = i18n.__("Standby")
              when 9 then  newStatus = i18n.__("Boot Loading")
              when 10 then  newStatus = i18n.__("Error")
              else newStatus = i18n.__("Startup")

          @base.setAttribute 'status', i18n.__(newStatus)
          @base.setAttribute 'energyToday', Number data.DAY_ENERGY.Value  if @_has data, "DAY_ENERGY.Value"
          @base.setAttribute 'energyYear', Number data.YEAR_ENERGY.Value  if @_has data, "YEAR_ENERGY.Value"
          @base.setAttribute 'energyTotal', Number data.TOTAL_ENERGY.Value  if @_has data, "TOTAL_ENERGY.Value"
          @base.setAttribute 'currentPower', if @_has data, "PAC.Value" then Number data.PAC.Value else 0.0
          @base.setAttribute 'currentAmperage', if @_has data, "IAC.Value" then Number data.IAC.Value else 0.0
          @base.setAttribute 'currentVoltage', if @_has data, "UAC.Value" then Number data.UAC.Value else 0.0
      )
      super(@config, @plugin, "GetInverterRealtimeData")

    destroy: () ->
      super()

    getStatus: -> Promise.resolve @status
    getEnergyToday: -> Promise.resolve @energyToday
    getEnergyYear: -> Promise.resolve @energyYear
    getEnergyTotal: -> Promise.resolve @energyTotal
    getCurrentPower: -> Promise.resolve @currentPower
    getCurrentAmperage: -> Promise.resolve @currentAmperage
    getCurrentVoltage: -> Promise.resolve @currentVoltage

  class AttributeContainer extends events.EventEmitter
    constructor: () ->
      @values = {}

  class FroniusComponentsDataDevice extends FroniusBaseDevice
    attributeTemplates =
      powerGenerate:
        type: "number"
        key: "Power_P_Generate"
        unit: "W"
        acronym : "P gen"
      powerLoad:
        type: "number"
        key: "Power_P_Load"
        unit: "W"
        acronym : "P load"
      powerGrid:
        type: "number"
        key: "Power_P_Grid"
        unit: "W"
        acronym : "P grid"
      powerAkkuSum:
        type: "number"
        key: "Power_Akku_Sum"
        unit: "W"
        acronym : "P bat"
      powerPvSum:
        type: "number"
        key: "Power_PV_Sum"
        unit: "W"
        acronym : "P pv"
      powerSelfConsumption:
        type: "number"
        key: "Power_P_SelfConsumption"
        unit: "W"
        acronym : "P self"
      relativeSelfConsumption:
        type: "number"
        key: "Relative_Current_SelfConsumption"
        unit: "%"
        acronym : "R self"
      relativeAutonomy:
        type: "number"
        key: "Relative_Current_Autonomy"
        unit: "%"
        acronym : "R autonomy"

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug ? false
      @base = commons.base @, @config.class unless @base?
      @attributeValues = new AttributeContainer()
      @attributes = _.cloneDeep(@attributes)

      for attributeName in @config.attributes
        do (attributeName) =>
          if attributeTemplates.hasOwnProperty attributeName
            properties = attributeTemplates[attributeName]
            @attributes[attributeName] =
              description: properties.description || attributeName.replace /(^[a-z])|([A-Z])/g, ((match, p1, p2, offset) =>
                (if offset>0 then " " else "") + match.toUpperCase())
              type: properties.type
              unit: properties.unit if properties.unit?
              acronym: properties.acronym if properties.acronym?

            @attributeValues.values[attributeName] = 0

            @attributeValues.on properties.key, ((value) =>
              @base.debug "Received update for", properties.key, value
              if value.value?
                @attributeValues.values[attributeName] = value.value
                @emit attributeName, value.value
            )

            @_createGetter(attributeName, =>
              return Promise.resolve @attributeValues[attributeName]
            )
          else
            @base.error "Configuration Error. No such attribute: #{attributeName} - skipping."

      super(@config, @plugin, "GetComponentsData")

      @on 'data', ((error, values) =>
        if error or not values
          if error
            @base.error error
        else
          data = values.Body.Data
          for key,value of data
            @attributeValues.emit key, value if value?
      )

    destroy: () ->
      super()

  class FroniusPowerFlowRealtimeDataDevice extends FroniusBaseDevice
    attributeTemplates =
      mode:
        type: "string"
        description: "Operation mode of the PV system, one of: produce-only, meter, vague-meter, bidirectional, isolated"
        key: "Mode"
        acronym : "mode"
      powerGrid:
        type: "number"
        key: "P_Grid"
        unit: "W"
        acronym : "P grid"
      powerLoad:
        type: "number"
        key: "P_Load"
        unit: "W"
        acronym : "P load"
      powerAkku:
        type: "number"
        key: "P_Akku"
        unit: "W"
        acronym : "P bat"
      powerGenerate:
        type: "number"
        key: "P_PV"
        unit: "W"
        acronym : "P gen"
      energyDay:
        type: "number"
        key: "E_Day"
        unit: "Wh"
        acronym : "E day"
      energyYear:
        type: "number"
        key: "E_Year"
        unit: "Wh"
        acronym : "E month"
      energyTotal:
        type: "number"
        key: "E_Total"
        unit: "Wh"
        acronym : "E total"

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug ? false
      @base = commons.base @, @config.class unless @base?
      @attributeValues = new AttributeContainer()
      @attributes = _.cloneDeep(@attributes)

      for attributeName in @config.attributes
        do (attributeName) =>
          if attributeTemplates.hasOwnProperty attributeName
            properties = attributeTemplates[attributeName]
            @attributes[attributeName] =
              description: properties.description || attributeName.replace /(^[a-z])|([A-Z])/g, ((match, p1, p2, offset) =>
                (if offset>0 then " " else "") + match.toUpperCase())
              type: properties.type
              unit: properties.unit if properties.unit?
              acronym: properties.acronym if properties.acronym?

            @attributeValues.values[attributeName] = 0

            @attributeValues.on properties.key, ((value) =>
              @base.debug "Received update for", properties.key, value
              if value?
                @attributeValues.values[attributeName] = value
                @emit attributeName, value
            )

            @_createGetter(attributeName, =>
              return Promise.resolve @attributeValues[attributeName]
            )
          else
            @base.error "Configuration Error. No such attribute: #{attributeName} - skipping."

      super(@config, @plugin, "GetPowerFlowRealtimeDataData")

      @on 'data', ((error, values) =>
        if error or not values
          if error
            @base.error error
        else
          data = values.Body.Data.Site
          for key, value of data
            @attributeValues.emit key, value if value?
      )

    destroy: () ->
      super()


  # ###Finally
  # Create a instance of my plugin
  myPlugin = new FroniusSolarPlugin
  # and return it to the framework.
  return myPlugin
