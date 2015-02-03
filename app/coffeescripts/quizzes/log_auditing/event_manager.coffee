define (require) ->
  K = require('./constants')
  QuizEvent = require('./event')
  EventBuffer = require('./event_buffer')
  jQuery = require('jquery')
  eraseFromArray = require('compiled/arr/erase')
  debugConsole = require('compiled/util/debugConsole')
  _ = require('underscore')

  {extend} = _
  {ajax} = jQuery
  jWhen = jQuery.when

  JSON_HEADERS = {
    'Accept': 'application/json; charset=UTF-8',
    'Content-Type': 'application/json; charset=UTF-8'
  }

  class EventManager
    @options: {
      autoDeliver: true
      autoDeliveryFrequency: 15000 # milliseconds
      deliveryUrl: '/quiz_submission_events'
    }

    constructor: (options={}) ->
      this.options = extend({}, EventManager.options, options)
      this._trackerFactories = []
      this._state = {
        trackers: []
        buffer: null
        deliveryAgent: null
        deliveries: []
      }

    registerTracker: (trackerFactory) ->
      this._trackerFactories.push(trackerFactory)

    # Install all the event trackers and start the event buffer consumer.
    #
    # EventTracker instances will be provided with a deliveryCallback that
    # enqueues events for delivery via this module.

    unregisterAllTrackers: ->
      this._trackerFactories = []

    start: ->
      state = this._state
      state.buffer = new EventBuffer()
      options = this.options
      enqueue = this._enqueue.bind(this)

      deliveryCallback = (tracker, eventData) ->
        event = new QuizEvent(tracker.getEventType(), eventData)
        enqueue(event, tracker.getDeliveryPriority())

      # generate tracker instances
      state.trackers = this._trackerFactories.map (Factory) ->
        tracker = new Factory()
        tracker.install(deliveryCallback.bind(null, tracker))
        tracker

      if options.autoDeliver
        this._startDeliveryAgent()

    # Are we collecting and delivering events?
    isRunning: ->
      !!this._state.buffer

    # Are there any events pending delivery?
    isDirty: ->
      this.isRunning() && !this._state.buffer.isEmpty()

    # Are there any events currently being delivered?
    isDelivering: ->
      this._state.deliveries.length > 0

    # Deliver newly tracked events to the backend.
    #
    # @return {$.Deferred}
    #   Resolves when the delivery of the current batch of pending events is
    #   done.
    deliver: () ->
      buffer = this._state.buffer
      deliveries = this._state.deliveries
      options = this.options

      eventSet = buffer.filter (event) ->
        event.isPendingDelivery()

      if eventSet.isEmpty()
        return jWhen()

      eventSet.markBeingDelivered()

      delivery = ajax({
        url: options.deliveryUrl,
        type: 'POST',
        global: false, # don't whine to the user if this fails
        headers: JSON_HEADERS,
        data: JSON.stringify({
          quiz_submission_events: eventSet.toJSON()
        })
      })

      delivery.then ->
        # remove the events we delivered from the buffer
        buffer.discard(eventSet)
      , ->
        # reset the events state, we'll try to deliver them again with the next
        # batch:
        eventSet.markPendingDelivery()

      untrackDelivery = ->
        eraseFromArray(deliveries, delivery)

      delivery.then untrackDelivery, untrackDelivery
      deliveries.push(delivery)

      return delivery

    # Undo what #start() did.
    #
    # QuizLogAuditing stops existing once this is called.
    stop: (force=false) ->
      state = this._state

      if this.isDelivering() && !force
        console.warn """
          You are attempting to stop the QuizLogAuditing module while a delivery
          is in progress.
        """

        return jWhen(state.deliveries).done(this.stop.bind(this, true))

      state.buffer = null

      if state.deliveryAgent
        this._stopDeliveryAgent()

      state.trackers.forEach (tracker) ->
        tracker.uninstall()

      state.trackers = []

      return jWhen()

    _startDeliveryAgent: ->
      this._state.deliveryAgent = setInterval(
        this.deliver.bind(this),
        this.options.autoDeliveryFrequency
      )

    # Queue an event for delivery.
    #
    # This is what the deliveryCallback will end up calling.
    #
    # @param {Event} event
    # @param {Number} [priority=0]
    _enqueue: (event, priority) ->
      this._state.buffer.push(event)

      debugConsole.log("Enqueuing #{event} for delivery.")

      if priority == K.EVT_PRIORITY_HIGH
        if !this.isDelivering()
          this.deliver()
        else
          jWhen(this._state.deliveries).done(this.deliver.bind(this))

    _stopDeliveryAgent: ->
      this._state.deliveryAgent = clearInterval(this._state.deliveryAgent)