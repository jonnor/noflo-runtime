noflo = require 'noflo'

class ConnectRuntime extends noflo.Component
  constructor: ->
    @element = null
    @inPorts = new noflo.InPorts
      definition:
        datatype: 'object'
        description: 'Runtime definition object'
        required: true
      element:
        datatype: 'object'
        description: 'DOM element to be set as Runtime parent element'
        required: false
    @outPorts = new noflo.OutPorts
      runtime:
        datatype: 'object'
        description: 'FBP Runtime instance'
        required: true
      error:
        datatype: 'object'
        description: 'Runtime connection error'
        required: false

    @inPorts.on 'definition', 'data', (data) =>
      @connect data
    @inPorts.on 'element', 'data', (@element) =>

  validate: (definition) ->
    unless definition.protocol
      @outPorts.error.send new Error 'Protocol definition required'
      @outPorts.error.disconnect()
      return false
    unless definition.address
      @outPorts.error.send new Error 'Address definition required'
      @outPorts.error.disconnect()
      return false
    true

  connect: (definition) ->
    return unless @validate definition

    try
      Runtime = require "/noflo-noflo-runtime/src/runtimes/#{definition.protocol}"
    catch e
      @outPorts.error.send new Error "Protocol #{definition.protocol} is not supported"
      @outPorts.error.disconnect()
      return

    rt = new Runtime definition
    rt.setParentElement @element if @element
    try
      rt.connect()
    catch e
      @outPorts.error.send e
      @outPorts.error.disconnect()
      return

    @outPorts.runtime.beginGroup definition.id
    @outPorts.runtime.send rt
    @outPorts.runtime.endGroup()
    @outPorts.runtime.disconnect()

exports.getComponent = -> new ConnectRuntime
