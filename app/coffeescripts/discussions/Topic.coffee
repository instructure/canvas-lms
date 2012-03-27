define [
  'compiled/backbone-ext/Backbone'
  'compiled/util/BackoffPoller'
], (Backbone, BackoffPoller) ->

  ##
  # Model for a topic, the initial data received from the server
  class Topic extends Backbone.Model

    defaults:
      # people involved in the conversation
      participants: []

      # ids for the entries that are unread
      unread_entries: []

      # the whole discussion tree, EntryCollections are made out of
      # these
      view: null

    url: ENV.DISCUSSION.ROOT_URL

    fetch: (options = {}) ->
      loader = new BackoffPoller @url, (data, xhr) =>
        return 'continue' if xhr.status is 503
        return 'abort' if xhr.status isnt 200
        @set(@parse(data, 200, xhr))
        options.success?(this, data)
        # TODO: handle options.error, perhaps with Backbone.wrapError
        'stop'
      ,
        handleErrors: true
        initialDelay: false
        # we'll abort after about 10 minutes
        baseInterval: 2000
        maxAttempts: 11
        backoffFactor: 1.6
      loader.start()

