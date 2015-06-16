define (require) ->
  K = require('./constants')

  # A convenience wrapper for an array of quiz events that allows us to operate
  # on all contained events.
  #
  # You don't create sets directly, instead, the EventBuffer API may return
  # these objects when appropriate.
  class EventSet
    constructor: (events) ->
      @_events = events

    isEmpty: ->
      @_events.length == 0

    markPendingDelivery: ->
      @_events.forEach (event) ->
        event._state = K.EVT_STATE_PENDING_DELIVERY

    markBeingDelivered: ->
      @_events.forEach (event) ->
        event._state = K.EVT_STATE_IN_DELIVERY

    # Serialize the set of events, ready for transmission to the API.
    toJSON: ->
      @_events.map (event) ->
        event.toJSON()