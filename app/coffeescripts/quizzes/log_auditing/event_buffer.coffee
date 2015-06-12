define (require) ->
  K = require('./constants')
  QuizEvent = require('./event')
  QuizEventSet = require('./event_set')
  debugConsole = require('compiled/util/debugConsole')

  STORAGE_ADAPTERS = [
    K.EVT_STORAGE_MEMORY,
    K.EVT_STORAGE_LOCAL_STORAGE
  ]

  # The buffer is basically where we're storing the captured events pending
  # delivery. The buffer tries to act like an array although it isn't one, but
  # the API should feel familiar.
  #
  # The buffer could also be configured with different storage adapters; memory
  # or localStorage. See #setStorageAdapter for configuring it.
  class EventBuffer
    @STORAGE_ADAPTER: K.EVT_STORAGE_MEMORY
    @setStorageAdapter: (adapter) ->
      if STORAGE_ADAPTERS.indexOf(adapter) == -1
        throw new Error """
          Unsupported storage adapter "#{adapter}". Available adapters are:
          #{STORAGE_ADAPTERS.join(', ')}
        """

      EventBuffer.STORAGE_ADAPTER = adapter

    # Load from localStorage on creation if available.
    constructor: ->
      @useLocalStorage = EventBuffer.STORAGE_ADAPTER == K.EVT_STORAGE_LOCAL_STORAGE
      @_events = @_load() || []

      debugConsole.debug('EventBuffer: using', @constructor.STORAGE_ADAPTER, 'for storage')

    # Add an event to the buffer and update persisted state if available.
    push: (event) ->
      @_events.push(event)
      @_save()

    isEmpty: ->
      @_events.length == 0

    getLength: ->
      @_events.length

    # @return {EventSet}
    filter: (callback) ->
      new QuizEventSet(@_events.filter(callback))

    # Remove events in a set from the buffer. Usually you'd use this after
    # delivering the events that were pending delivery.
    #
    # @param {EventSet} eventSet
    discard: (eventSet) ->
      ids = eventSet._events.map (event) -> event._id

      @_events = @_events.filter (event) ->
        ids.indexOf(event._id) == -1

      @_save()

      return undefined

    # Serialize the buffer.
    toJSON: ->
      @_events.map (event) ->
        event.toJSON()

    _save: ->
      if @useLocalStorage
        try
          localStorage.setItem(K.EVT_STORAGE_KEY, JSON.stringify(this.toJSON()))
        catch e
          debugConsole.warn """
            Unable to save to localStorage, likely because we're out of space.
          """

      return undefined

    _load: ->
      if @useLocalStorage
        jsonEvents = JSON.parse(localStorage.getItem(K.EVT_STORAGE_KEY) || '[]')
        jsonEvents.map (descriptor) ->
          QuizEvent.fromJSON(descriptor)
      else
        return undefined