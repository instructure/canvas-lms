define (require) ->
  _ = require('underscore')
  K = require('./constants')
  generateUUID = require('../../util/generateUUID')
  {clone} = _

  class QuizEvent
    # @internal Create an Event from the JSON version stored in localStorage.
    @fromJSON: (descriptor) ->
      event = new QuizEvent(descriptor.event_type, descriptor.event_data)
      event.recordedAt = new Date(descriptor.created_at)
      event

    constructor: (type, data) ->
      if !type
        throw new Error("An event type must be specified.")

      this._id = generateUUID()
      this._state = K.EVT_STATE_PENDING_DELIVERY

      # @property {String} type
      #
      # A unique type specifier for this event.
      # This is a required property.
      #
      # See ./constants.js for the defined event types.
      this.type = type

      # @property {Mixed} [data=null]
      #
      # Custom event data. This *may* be present.
      this.data = clone(data)

      # @property {Date} recordedAt
      # @readonly
      #
      # Time at which the event was recorded. This is always present.
      this.recordedAt = new Date()

    isPendingDelivery: ->
      this._state == K.EVT_STATE_PENDING_DELIVERY

    isBeingDelivered: ->
      this._state == K.EVT_STATE_IN_DELIVERY

    wasDelivered: ->
      this._state == K.EVT_STATE_DELIVERED

    toJSON: ->
      {
        event_type: this.type,
        event_data: this.data,
        client_timestamp: this.recordedAt
      }

    toString: ->
      JSON.stringify(this.toJSON())