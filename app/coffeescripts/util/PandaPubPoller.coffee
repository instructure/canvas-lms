define ['compiled/PandaPub', 'jquery'], (pandapub, $) ->

  # This class handles the common logic of "use PandaPub when available,
  # otherwise poll".

  class

    # Create a new PandaPubPoller.
    #
    # @pollInterval (ms) - How long to poll when pandapub is disabled
    # @rarePollInterval (ms) - How long to poll when pandapub is enabled
    # @pollCB - The function to call when we should poll. Normally this will
    #   wrap your normal poll method. It is passed another function that should
    #   be called when the poll is complete.

    constructor: (@pollInterval, @rarePollInterval, @pollCB) ->
      @running = false
      @lastUpdate = null

      # make sure our timer doesn't fire again as leaving the page
      # workaround for https://code.google.com/p/chromium/issues/detail?id=263981
      $(window).on 'beforeunload', =>
        @stopTimeout() if @timeout

    # Configures the PandaPub channel and token.

    setToken: (@channel, @token) ->
      @subscribe() if pandapub.enabled and @running

    # Set the function to call when data is received via the streaming
    # channel.

    setOnData: (@streamingCB) ->

    # Starts polling/streaming.

    start: =>
      @lastUpdate = Date.now()
      @running = true
      @startTimeout()
      @subscribe() if pandapub.enabled

    # Stop polling/streaming.

    stop: =>
      @stopTimeout()
      @unsubscribe() if pandapub.enabled
      @running = false

    isRunning: =>
      @running

    # Start the timeout that schedules the periodic polling consideration.
    #
    # @api private

    startTimeout: =>
      @timeout = setTimeout(@considerPoll, @pollInterval)

    # Stop the timeout
    #
    # @api private

    stopTimeout: =>
      clearTimeout(@timeout)

    # Triggers a poll based on time passed since last data received, and
    # whether pandapub is enabled
    #
    # @api private

    considerPoll: =>
      interval = @pollInterval

      if pandapub.enabled
        interval = @rarePollInterval

      if Date.now() - @lastUpdate >= interval
        @pollCB(@pollDone)
      else
        @startTimeout()

    # Fired when a poll completes
    #
    # @api private

    pollDone: =>
      @lastUpdate = Date.now()
      @startTimeout()

    subscribe: =>
      # TODO: make this smart so you can update credentials periodically
      return if @subscription

      # don't attempt to subscribe until we get a channel and a token
      return unless @channel and @token

      @subscription = pandapub.subscribe @channel, @token, (message) =>
        @lastUpdate = Date.now()
        @streamingCB(message)

    unsubscribe: =>
      @subscription.cancel() if @subscription
