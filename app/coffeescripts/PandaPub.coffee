define [ 'INST', 'jquery' ], (INST, $) ->

  class Client
    constructor: ->
      @faye = null
      @tokens = {}

    # Is truthy if PandaPub is enabled.
    #
    enabled:
      INST.pandaPubSettings

    # Subscribe to a channel with a token. Returns an object
    # which can receive a .cancel() call in order to unsubscribe.
    # That object is also a Deferred, to find out when the subscription
    # is successful or failed.
    #
    subscribe: (channel, token, cb) =>
      fullChannel = "/#{INST.pandaPubSettings.application_id}#{channel}"

      @tokens[fullChannel] = token

      dfd = new $.Deferred
      dfd.cancel = ->

      @client (faye) =>
        subscription = faye.subscribe fullChannel, (message) ->
          cb(message)

        subscription.then dfd.resolve, dfd.reject
        dfd.cancel = ->
          subscription.cancel()

      dfd


    # Subscribe to transport-level events, transport:down or
    # transport:up. See http://faye.jcoglan.com/browser/transport.html

    on: (event, cb) =>
      @client (faye) =>
        faye.on(event, cb)


    # @api private

    authExtension: =>
      outgoing: (message, cb) =>
        if message.channel == '/meta/subscribe'
          if message.subscription of @tokens
            message.ext ||= {}
            message.ext.auth =
              token: @tokens[message.subscription]

        cb(message)

    # Creates or returns the internal Faye client, loading it first
    # if necessary.
    #
    # @api private

    client: (cb) ->
      if @faye then cb(@faye)

      unless @faye
        require [ INST.pandaPubSettings.push_url + '/client.js' ], =>
          @faye = new window.Faye.Client INST.pandaPubSettings.push_url
          @faye.addExtension @authExtension()
          cb @faye


  # We return a singleton instance of our client.
  new Client
